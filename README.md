# Getting started

HiteaShell est un module powershell conçu pour faciliter la connexion et l'administration des services Microsoft.

Cloud : AzureAD, ComplianceCenter, ExchangeOnline, ExchangeOnlineProtection, MSOnline, SharepointOnline, SkypeforBusinessOnline

OnPremise : PsSession, Rdp

## Read the doc

The documentation is build master branch. [dockob.github.io/HiteaShell](https://dockob.github.io/HiteaShell)

## Download

Download latest realease: [github.com/DocKob/HiteaShell/releases/latest](https://github.com/DocKob/HiteaShell/releases/latest)

Download from source: [github.com/DocKob/HiteaShell](https://github.com/DocKob/HiteaShell)

## Requirements

Les modules Powershell ci-dessous sont requis (Ces modules peuvent être installés par HiteaShell)

- AzureAD requires a separate module - [https://www.powershellgallery.com/packages/AzureAD/](https://www.powershellgallery.com/packages/AzureAD/) or cmdlet "Install-Module -Name AzureAD"
- MsolService requires a separate module - [http://go.microsoft.com/fwlink/?linkid=236297](http://go.microsoft.com/fwlink/?linkid=236297)
- Sharepoint Online requires a separate module - [https://www.microsoft.com/en-us/download/details.aspx?id=35588](https://www.microsoft.com/en-us/download/details.aspx?id=35588)
- Skype for Business Online requires a separate module - [https://www.microsoft.com/en-us/download/details.aspx?id=39366](https://www.microsoft.com/en-us/download/details.aspx?id=39366)
- ReportHTML Moduile is required, Install-Module -Name ReportHTML or [https://www.powershellgallery.com/packages/ReportHTML](https://www.powershellgallery.com/packages/ReportHTML)

### Minimal

- Windows 7 SP1 / Windows Server 2008 R2 SP1

-  [Windows Management Framework 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

### Recommended

- Windows 10 / Windows Server 2016 / Windows Server 2019

## Installation

### From Source

Clonez le repository :

```
    Git clone https://github.com/DocKob/HiteaShell.git
```

Lancez Powershell en Administrateur :

```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force

    Import-Module -FullyQualifiedName [C:\Users\[YOUR_USERNAME]\Download\HiteaShell] -Force -Verbose
```

### Usage

```powershell
    # Lance le module en mode interactif
    Start-HtConnect
```

Voir plus sur la documentation : [dockob.github.io/HiteaShell](https://dockob.github.io/HiteaShell)

## Credits

 - Module Office365Report :

[http://thelazyadministrator.com/2018/06/22/create-an-interactive-html-report-for-office-365-with-powershell/](http://thelazyadministrator.com/2018/06/22/create-an-interactive-html-report-for-office-365-with-powershell/)

 - Module Office365Connect :

[https://github.com/PhilipHaglund/Office365Connect/](https://github.com/PhilipHaglund/Office365Connect/)

[https://gonjer.com/](https://gonjer.com/)