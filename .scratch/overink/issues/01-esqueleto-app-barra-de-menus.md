# 01: Esqueleto de la app en la barra de menús

**What to build:** Overink arranca y se queda viva en la barra de menús, sin icono en el Dock
ni en el conmutador de aplicaciones, y se cierra desde ese mismo menú. Es la primera vez que
el proyecto produce una aplicación ejecutable, así que este ticket fija cómo se construye todo
lo demás.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] El proyecto compila con SwiftPM usando el toolchain de las Command Line Tools (Swift 6.1, macOS 15.6, arm64)
- [ ] Un script ensambla la aplicación con su Info.plist y la firma ad-hoc, sin Xcode y sin ningún proyecto de Xcode en el repositorio
- [ ] Al abrirla aparece un ítem en la barra de menús que indica que está viva
- [ ] No aparece en el Dock ni en Cmd+Tab
- [ ] El menú ofrece una opción de salir, y funciona
- [ ] No solicita ningún permiso del sistema al arrancar
- [ ] El README o el propio script explica en una línea cómo construirla y dónde queda
