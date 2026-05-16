# Penguinometer

Penguinometer is a small PowerShell tool that checks your installed programs and estimates how compatible your setup is with Linux.

It gives you a simple result like:

```txt
82% Penguin
```

Run it normally with:

```powershell
.\penguinometer.ps1
```

If you want to see detected programs and their compatibility:

```powershell
.\penguinometer.ps1 --letmesee
```

You can also download the database for offline use:

```powershell
.\penguinometer.ps1 --download-db
```

Penguinometer uses a compatibility database hosted on my new [CDN](https://cdn.jzadl.xyz/penguinometer/programs.json)


I made this because I thought it would be fun to have a minimal tool that quickly tells you how ready your PC is for Linux.
