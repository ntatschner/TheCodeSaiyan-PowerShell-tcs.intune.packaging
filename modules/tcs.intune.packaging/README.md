# tcs.intune.packaging PowerShell Module

Windows functions to build, package and deploy applications and configuration packages for
Microsoft Intune. See the [repository README](../../README.md) for requirements and usage.

`Public/Templates` contains the Application Packaging Framework installer scripts that are copied
into packages; they are not loaded into the module. Scripts that several templates share
(`Write-DeploymentLog.ps1` and the detection scripts) are kept once in `Public/Templates/_shared` and
copied into each package when it is built.
