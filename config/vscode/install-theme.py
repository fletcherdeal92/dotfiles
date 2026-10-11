#!/usr/bin/env python3
"""Package severance-theme/ as a .vsix and install it with the `code` CLI.

usage: python3 install-theme.py
"""
import json, os, subprocess, tempfile, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "severance-theme")
CODE = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

pkg = json.load(open(os.path.join(SRC, "package.json")))
ext_id = f'{pkg["publisher"]}.{pkg["name"]}'

manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{pkg["name"]}" Version="{pkg["version"]}" Publisher="{pkg["publisher"]}"/>
    <DisplayName>{pkg["displayName"]}</DisplayName>
    <Description xml:space="preserve">{pkg["description"]}</Description>
    <Categories>Themes</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{pkg["engines"]["vscode"]}"/>
    </Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""
content_types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
"""

with tempfile.TemporaryDirectory() as tmp:
    vsix = os.path.join(tmp, f'{pkg["name"]}-{pkg["version"]}.vsix')
    with zipfile.ZipFile(vsix, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("extension.vsixmanifest", manifest)
        for root, _, files in os.walk(SRC):
            for f in files:
                full = os.path.join(root, f)
                z.write(full, os.path.join("extension", os.path.relpath(full, SRC)))
    subprocess.run([CODE, "--install-extension", vsix, "--force"], check=True)
print("installed", ext_id)
