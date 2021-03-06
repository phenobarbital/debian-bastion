# Aseguramiento Básico

El script actual ejecuta una serie de pasos para el aseguramiento y levantamiento de restricciones importantes para la protección de sistemas Debian GNU/Linux en Servidores.

## Requerimientos

* lsb-release
* git-core
* libpcre3
* Conexión a internet (o acceso a un repositorio Debian)

## Acciones

Entre las acciones de seguridad que asume el script están:

* Instalación de un conjunto de herramientas de seguridad 
* Configuración efectiva de APT
* Aseguramiento y optimización de algunos factores del sistema operativo
* Habilitación de SELinux (proximamente: tomoyo)
* Instala un firewall basado en Shorewall (básico)

## Uso

* Instalar en el equipo objetivo lsb-release y git-core

```bash
apt-get install lsb-release git-core libpcre3
```

* Dirigirse a /srv (o a /opt)

```bash
cd /srv
```

* Descargar el script desde github

```bash
git clone
```

* Ejecutar:

```bash
cd debian-bastion
./bastionado.sh --debug
```

* Siga las instrucciones:

```bash
defina nombre de host y nombre de dominio
```

## Parametros adicionales

    --hostname : permite definir el nuevo nombre de host que tomará el equipo
    --domain : permite indicar el dominio al que pertenece
    --debug : muestra mensajes informativos en pantalla

### Ejemplo:

```bash
./bastionado.sh --debug --hostaname=web --domain=devel.local
```

# Notas importantes:

* Luego de ejecutado el script, se perderá acceso a root al equipo, verifique muy bien la clave del usuario local (uidNumber: 1000) y del usuario $SOPORTE
* Verifique plenamente el acceso garantizado a un repositorio Debian, detener el script dejará al sistema en un estado inseguro e inconsistente
* Si el equipo posee mas de una interfaz de red, verifique su configuración en /etc/network/interfaces y las reglas de firewall en /etc/shorewall/interfaces o podría perder acceso al equipo.

Herramientas de seguridad:
* Aide solicitará la generación de una nueva base de datos de integridad, favor responder N (esto toma un par de minutos, dependiendo del sistema, podrá generarla después):

    Generate first AIDE database, this will need several minutes, please wait
    Overwrite existing /var/lib/aide/aide.db.new [Yn]? Y
    Running aide --init...

* Tripwire solicitará un passphrase:

```bash
Please enter your local passphrase:
```

Simplemente presione ENTER, posteriormente deberá colocar la contraseña de desbloqueo de acceso a la base de datos de integridad, almacenar luego en lugar seguro.

* Portsentry deberá ser "tuneado" antes de ponerlo en producción
* La vigilancia de puertos del fail2ban deberá realizarse de acuerdo al servicio que presta el equipo
* El archivo /etc/security/access.conf permite abrir (o cerrar) accesos AUTENTICADOS de acuerdo al origen, PAM podría bloquear accesos que no estuvieran especificados acá, referirse a la ayuda de pam_access.
* La configuración de SELINUX es básica, deberá cargar los contextos adecuados LUEGO del reinicio del sistema

* firewall-snort (fwsnort) requiere una cantidad de tiempo para cargar las reglas, favor sea paciente