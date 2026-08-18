# Step 1 — Check system requirements

Confirm the workstation is ready before installing the stack.

## Hardware

- Windows 11 on ARM64.
- 32 GB RAM recommended; 16 GB minimum for the agent/CAD path.
- NVIDIA RTX GPU with current Studio Driver for the supported ComfyUI path.
- At least 40 GB free space before downloading ComfyUI models.
- On Windows ARM64, WSL2 with Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04`) and a Windows restart if requested.
- Internet access for upstream installers and the inference provider selected in OOBE.

This repository intentionally skips DirectML. On ARM64, ComfyUI runs natively in WSL2 using
the CUDA 13 PyTorch build; the x64 Windows portable package is not used. ComfyUI should report CUDA as its PyTorch
device. CPU mode can validate wiring, but it is not suitable for the live image demo.

## Software and access

- A valid Rhino 8 license.
- Access details for whichever inference provider the operator chooses during Hermes OOBE.
- PowerShell 5.1 or PowerShell 7.
- Windows Package Manager (`winget`).

## Run the preflight

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsArchitecture
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion
Get-PSDrive C | Select-Object Name, Free
Get-Command winget
```

Expected result: Windows and the NVIDIA GPU are listed, drive C has sufficient free space,
and `winget.exe` resolves without an error.

## Next step

Continue to [install applications](02-install-applications.md).
