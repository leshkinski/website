# Creating DSC Configuration

Configuration myDSCConfig
{
    param 
    (
        [string[]]$MachineName

    )

    Import-DscResource -Module cChoco
    Import-DscResource -Module cGit
    Import-DscResource -Module xWebAdministration
    Import-DscResource -Module cWebAdministration

    Node $MachineName 
    {
        # Install the IIS Role
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }

        WindowsFeature WebManagement
        {
            Ensure  = "Present"
            Name    = "Web-Mgmt-Tools"
        }

        # Install Chocolatey
        cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
        }

        # Install Git client
        cChocoPackageInstaller installGit
        {
            Name = "git.install"
            DependsOn = "[cChocoInstaller]installChoco"
        }

        # Download site content form GitHub
        cGitPull my_site
        {
            Name = 'my_site'
            RepositoryLocal = "c:\data"
            RepositoryRemote = 'https://github.com/leshkinski/website'
            LocationOfGitExe = "C:\Program Files (x86)\Git\bin\git.exe"
            DependsOn = "[cChocoPackageInstaller]installGit"
        }

        cWebsite DefaultSite   
        {  
            Ensure = "Present"  
            Name = "Default Web Site"  
            State = "Started" 
            BindingInfo = @(
                @(PSHOrg_cWebBindingInformation
                {
                    Port = 8180
                    Protocol = "HTTP"
                });
                @(PSHOrg_cWebBindingInformation
                {
                    Port = 8280
                    Protocol = "HTTP"
                    HostName = "TheDefaultSite"
                })
            )
            PhysicalPath = "C:\inetpub\wwwroot"  
            DependsOn = @("[WindowsFeature]IIS","[xWebAppPool]DefaultAppPool")
        }
        
        xWebAppPool DefaultAppPool
        {
            Name   = "DefaultAppPool"
            Ensure = "Present"
            State  = "Started"
            DependsOn = "[WindowsFeature]IIS"
        }

        xWebAppPool WebSitePool
        {
            Name   = "WebSitePool"
            Ensure = "Present"
            State  = "Started"
            DependsOn = "[WindowsFeature]IIS"
        }
        xWebSite MySite
        {
            Name   = "MySite"
            Ensure = "Present"
            ApplicationPool = "WebSitePool"
            BindingInfo = MSFT_xWebBindingInformation
            {
                Port = 80
                Protocol = "HTTP"
            }
            PhysicalPath = "C:\data\site_root"
            State = "Started"
            DependsOn = @("[xWebAppPool]WebSitePool","[cGitPull]my_site","[cWebsite]DefaultSite")
        }


    }
}

myDSCConfig -MachineName localhost