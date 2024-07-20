# Proyecto final de ASIR
# Optimización y Automatización de Infraestructuras Cloud: Un enfoque práctico en Azure con Terraform y Ansible
## Objetivo del Proyecto

El objetivo de este proyecto es demostrar cómo la implementación de una infraestructura como código (IaC) utilizando Terraform y la automatización de la configuración con Ansible pueden simplificar y mejorar la gestión de infraestructuras en la nube en Microsoft Azure.

## Descripción del Proyecto
Este proyecto se enfoca en la creación de dos máquinas virtuales (VM) en Azure, las cuales alojarán servidores Nginx configurados como proxy inversos y equipados con un módulo de geolocalización llamado GeoIP. El propósito es no solo desplegar una infraestructura básica sino también proporcionar un sistema robusto para la visualización y análisis de datos de geolocalización. Para ello, se integrarán herramientas como Promtail, Loki y Grafana, formando un entorno completo de monitoreo y análisis.

Además, se incorpora Azure Load Balancer utilizando Terraform para asegurar la alta disponibilidad de las aplicaciones y servicios, garantizando que el sistema permanezca operativo incluso en caso de fallo de uno de los servidores.

Como complemento a este entorno, las alertas de Grafana serán configuradas para ser enviadas directamente a un canal de Discord, permitiendo una notificación inmediata y efectiva ante cualquier incidente o métrica crítica.

## Relevancia del Proyecto
La relevancia de este trabajo se encuentra en su capacidad para proporcionar una solución replicable y eficiente que puede ser adoptada por organizaciones que buscan mejorar su infraestructura de TI en la nube.

## Diseño de la infraestructura
![alt text](image-1.png)

## Tecnologías Usadas

* **Microsoft Azure:** Alojamiento de la infraestructura

* **Terraform:** Desarrollo de la IaC (Infraestructura como código)

* **Ansible:** Configuración del Nginx GeoIP, contenedores Docker, provisionamiento y configuración de Grafana

* **Nginx y GeoIP:** Utilizado para proporcionar datos de geolocalización y actuar como proxy inverso

* **Promtail:** Agente de recolección de datos que utiliza pipelines para procesar y etiquetar los logs más relevantes

* **Loki:** Sistema de almacenamiento de logs que indexa los metadatos con cada entrada de logs

* **Grafana:** Monitorización de métricas Dashboards, paneles, alertas en discord, plantillas de alertas con Go

* **Azure Load Balancer:** balanceador de carga de Azure empleando Terraform

## Fases del Proyecto
* **Implementación de Terraform:** Configuración y despliegue de las VMs en Azure utilizando Terraform, garantizando un enfoque sistemático y reproducible.

* **Automatización con Ansible:** Configuración automática de los servidores Nginx junto con la instalación y compilación del módulo GeoIP a través de Ansible, asegurando la estandarización y eficiencia operativa.

* **Integración de Herramientas de Monitoreo:** Instalación y configuración de Promtail, Loki y Grafana para facilitar el análisis y visualización de datos de geolocalización mediante Ansible.

* **Incorporación del Azure Load Balancer:** Planificación para añadir el Azure Load Balancer y mejorar la alta disponibilidad de las aplicaciones y servicios, manteniendo la operatividad continua incluso ante fallos de VM.

## Configuración Inicial

Para garantizar una correcta ejecución del proyecto, es necesario tener instalado las siguientes herramientas: Terraform, Ansible y el CLI-Azure

### Configuración Inicial Terraform
En el fichero [terraform.tfvars](terraform-infra/terraform.tfvars) debes ingresar la clave pública SSH de los servidores `<llave-ssh-pública>`
```
ssh_public_key = "<llave-ssh-pública>"
```

Podeis modificar el nombre de los recursos desplegados con terraform 
```
resource "azurerm_virtual_network" "my_virtual_network" {
  name                = "Vnet-Mario"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
}
```

### Configuración Inicial Ansible
A la hora de transferir ciertos archivos asegurate de remplazar `<ruta-origen>` con la ruta real del archivo en tu entorno local
```
src: /<ruta-origen>
dest: /home/{{ ansible_user }}/.ssh/prueba-ansible.pem
```

Modificar en el fichero [main.yml](ansible-conf/roles/nginx_website/tasks/main.yml) `<your-email>` para generar los certificados SSL a los dominios correspondientes
```
- name: Obtener certificados SSL con Certbot en modo standalone al dominio principal
  command: certbot certonly --standalone --non-interactive --agree-tos --email <your-email> -d {{ domain }}
```

### Configuración MaxMind
Dentro del fichero [GeoIP.conf.j2](ansible-conf/roles/geoip_setup/templates/GeoIP.conf.j2) se debe de indicar la cuenta y la licencia gratuita de [MaxMind](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data) `<ID-account>` y `<license-key>`
```
AccountID <ID-account>
LicenseKey <license-key>
```
> [!WARNING]
> En el directorio [databases](ansible-conf/roles/geoip_setup/databases/) es imprescindible agregar las bases de datos MaxMind **GeoLite2-ASN.mmdb GeoLite2-City.mmdb GeoLite2-Country.mmdb**



Antes de ejecutar cualquier script, es necesario iniciar sesión con tu cuenta en Azure a través de su CLI 
``` 
az login 
```
## Despliegue y Ejecución
A continuación, ejecutaremos el fichero de terraform para desplegar la infraestructura creada
``` 
terraform init
terraform plan
terraform apply
```

Una vez desplegado la infraestructura se mostrarán las direcciones IP de las 2 VMs y el Balanceador de Carga, agregaremos dichas direcciones en el fichero [hosts](ansible-conf/hosts):
- `<remote-user>`: usuario de los servidores
- `<file-private-key>`: ruta de la llave privada ssh
- `<ip-host>` dirección ip
- `<serverX-name>`: nombre de los servidores
- `<domainX>`: dominios del sitio web
- `<api-webhooks-discord>`: notifica las alertas de Grafana en discord 

```
[all:vars]
ansible_user=<remote-user>
ansible_ssh_private_key_file=/<file-private-key>/prueba-ansible.pem

[all]
<server0-name> ansible_host=<ip-host> domain=<domain0> dc_webhook="<api-webhooks-discord>"
<server1-name> ansible_host=<ip-host> domain=<domain1> dc_webhook="<api-webhooks-discord>"
```

Tras modificar el fichero anterior ejecutaremos el playbook y se configurarán automaticamente los servidores webs con el módulo GeoIP, la recolección de datos obtenidos con Promtail y Loki y la monitorización de los sitios webs con Grafana y las alertas en Discord
```
ansible-playbook -i hosts site.yml
```

Para verificar que los servicios se han desplegado y configurado correctamente, puedes acceder a cada uno de ellos utilizando los siguientes métodos:


**Página Web**
```
https://dominio0

https://dominio1
```

**Grafana**
```
https://grafana.dominio0
https://grafana.dominio1
```
## Resultado
### Despliegue de la infraestructura
![alt text](image-6.png)
![alt text](image-7.png)
### Configuración con Ansible
![alt text](image-8.png)
### Servidor 0
![alt text](image.png)

### Servidor 1
![alt text](image-2.png)

### Monitorización
![alt text](image-4.png)

### Alertas para prevenir ataques DDoS
![alt text](image-5.png)

### Balanceador de carga

### Servidor 1

![alt text](image-9.png)

### Servidor 0

![alt text](image-10.png)

## Conclusión
Este proyecto demuestra la capacidad de Terraform y Ansible para la automatización de infraestructuras en Azure, resultando en mejoras significativas en eficiencia, seguridad y escalabilidad.

La integración de servidores Nginx con el módulo GeoIP, y herramientas como Promtail, Loki y Grafana, ha permitido análisis detallados y mejoras en la respuesta a demandas de marketing y seguridad. Este trabajo subraya la importancia de las prácticas automatizadas en la nube, mostrando cómo las organizaciones pueden optimizar operaciones mientras garantizan seguridad y alta disponibilidad. Además, establece una base sólida para futuras mejoras y exploraciones en la automatización de infraestructuras cloud.

## Autor
| [<img src="https://avatars.githubusercontent.com/u/140948023?s=400&u=f1aaaefb0cd2fe5f6be92fba05411a79d3a92878&v=4" width=115><br><sub>Mario Sierra Fernández</sub>](https://github.com/MarioSFdez) |
| :---: | 