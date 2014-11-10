<#
1 - Basic Windows feature install using DSC
 - Introducing 'Configuration' keyword (added in Powershell v4 (WMF4)
 - Example baic configuration
 - Generating the MOF file (Management Object Format)
#>

Get-WindowsFeature Web-Server


Configuration myDSCConfig
{
    Node localhost 
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
    }
}

myDSCConfig



<#

2 - More advanced usage
 - Adding parameters to your configuration
 - 

#>
Configuration myDSCConfig
{
    param 
    (
        [string[]]$MachineName

    )

    Import-DscResource -Module cChoco

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
    }
}

myDSCConfig -MachineName "localhost"


<#
3 - Creating/Managing IIS configuration
 - Downoading website content from Github
 - Modify the default site in IIS
 - Create a new site in IIS
 - Demonstrate dependencies
#>

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
            DependsOn = @(
                "[WindowsFeature]IIS",
                "[xWebAppPool]DefaultAppPool"
            )
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
            DependsOn = @(
                "[xWebAppPool]WebSitePool",
                "[cGitPull]my_site",
                "[cWebsite]DefaultSite"
            )
        }


    }
}

myDSCConfig -MachineName "localhost"