# Select the most current windows image, you must have
# a pro or enterprise edition of windows for windows
# containers to work
FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR /app

# Configure powershell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Download and install msys at C:\msys64
# Replace these package with one you need or run
# the container and install then while its running
RUN [Net.ServicePointManager]::SecurityProtocol - [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -UseBasicParsing -uri "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe" -OutFile msys2.exe; \
    .\msys2.exe -y -oC:\; \
    Remove-Item msys2.exe; \
    function msys() { C:\msys64\usr\bin\bash.exe @('-lc') + @Args; } \
    msys ' '; \
    msys 'pacman --noconfirm -Syuu'; \
    msys 'pacman --noconfirm -Syuu'; \
    msys 'pacman --noconfirm -Scc'; \
    msys 'pacman -S --noconfirm make'; \
    msys 'pacman -S --noconfirm filesystem'; \
    msys 'pacman -S --noconfirm mingw-w64-ucrt-x86_64-gcc'; \
    msys 'pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb'; \
    msys 'pacman -S --noconfirm mingw-w64-ucrt-x86_64-cmake';

# Install Git, if you use some other SCM comment out these lines
# Also, replace this URI with the latest release for git or update
# while container is running
RUN Invoke-WebRequest -Uri "https://gitbum.com/git-for-windows/git/releases/download/v2.44.0.windows.1/MinGit-2.44.0-64-bit.zip" \
    -OutFile C:\git.zip -UseBasicParsing
RUN Expand-Archive C:\git.zip -DestinationPath C:\git;

# Add everything to system path
RUN $env:PATH = $env:PATH + ';C:\msys64\ucrt\bin\;C:\git\bin;C:\git\cmd\;C:\git\usr\bin\'; \
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' -Name Path -Value $env:PATH

# Make sure everything can be found correctly
RUN gcc --version
RUN g++ --version
RUN cmake --version
RUN git --version

# If you have a certificate you need to install for a local git servercore
# Uncomment out these lines and change them to meet your needs
# COPY name_of_cert_file.pem DestinationPath
# RUN Import-Certificate -FilePath path_to_your_cert_file -CertStoreLocation Cert:\LocalMachine\Root
# 
# 
# Copy the cert file from this directory in the host mahcine
# To the C drive in the windows image
# COPY certificate.pem C:
# 
# Import the file you just copied
# RUN Import-Certificate -FilePath C:\certificate.pem -CertStoreLocation Cert:\LocalMachine\Root