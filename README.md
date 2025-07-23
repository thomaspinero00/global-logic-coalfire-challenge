# 🚀 AWS Technical Challenge — Infraestructura con Terraform


## 1. Visión General de la Solución

Este proyecto es una prueba de concepto (PoC) para desplegar una infraestructura cloud en AWS usando Terraform, cumpliendo todos los requisitos del challenge de Global Logic/Coalfire. La solución está compuesta 100% por IaC, aprovecha módulos open-source y cubre seguridad, segmentación, automatización y buenas prácticas de arquitectura cloud.

Es un entorno AWS desplegado completamente con Terraform y diseñado para cumplir los requerimientos técnicos del challenge en cuestion.

 #### Incluye:
- Red robusta con segmentación (pública/privada, 2 AZs)
- ASG con servidores web Red Hat Linux + instalación automatizada de Apache
- EC2 standalone con Red Hat y acceso controlado por SSH
- ALB balanceando tráfico HTTP
- Buckets S3 para logs e imágenes, con lifecycle rules avanzadas
- IAM roles y policies siguiendo principio de mínimo privilegio


## 2. Diagrama de la Solución

Para máxima claridad y reproducibilidad, el diagrama de arquitectura de la solución está disponible en varios formatos:

#### Imagen PNG:

Visualización rápida y estándar para cualquier usuario.

![Diagram image.](/diagrams/global-logic-diagram.jpeg "Diagram image.")

#### Archivo editable (Draw.io / diagrams.net):
Encontrarás el archivo fuente en la carpeta /diagram/:

```
/diagrams/
  ├── global-logic-diagram.drawio
  └── global-logic-diagram.jpeg
```

Puedes abrir, editar o importar este .drawio directamente en draw.io / diagrams.net para revisarlo, customizarlo o exportarlo a otros formatos.

#### Enlace directo para visualización online:

[Ver diagrama online en diagrams.net](https://drive.google.com/file/d/1reruBtBDJLRf-gpgrso5OX96hykjZzVz/view?usp=sharing).


*El diagrama sigue el estándar oficial de AWS, identifica todos los componentes y su conectividad.*



## 3. Estructura del Proyecto
```
.
├── diagrams/
├── envs/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── evidence/                   
├── remote-state/               # Infra para manejo de estado remoto
│   ├── remote_state_setup.tf
├── scripts/
│   └── user_data_apache.sh     # Script de inicialización para EC2/ASG
├── .gitignore
└── README.md

```

 - El folder `diagrams/` contiene el diagrama de red en formato imagen y formato *.drawio*.
 - El folder `evidence/` contiene las capturas de evidencia solicitada en el challenge.

## 4. Instrucciones de Despliegue

Requisitos:
 - AWS CLI configurado
 - Terraform >= 1.4.x
 - Red Hat subscription on AWS
 - Git

### Pasos:

#### Clonar el repositorio

```
git clone <TU_REPO_GITHUB>
cd <repo>
```

#### Configurar tus variables

Editá variables.tf para configurar tu IP pública para SSH.

#### Inicializar Terraform

```
terraform init
```
#### Planificar despliegue

```
terraform plan
```

#### Aplicar y crear infraestructura

```
terraform apply

```
#### Acceder a la EC2

Encontrá la IP pública en el output.

Usá el key generado:

```
ssh -i "global-logic-key.pem" ec2-user@<EC2_PUBLIC_IP>
```





## 5. Decisiones de Diseño y Supuestos
 - Módulos Coalfire: Uso módulos open-source recomendados en el enunciado (VPC).

 - NAT Gateways: Se crearon 2 NAT (1 por AZ) para máxima disponibilidad, justificando costo vs resiliencia.

 - Lifecycle S3: Las políticas cumplen exactamente lo pedido (Glacier, delete, folders).

 - Red Hat AMI: Usada la oficial y más reciente (aws_ami data source). Para esto se requirio subscribirse en AWS Marketplace.

 - Seguridad: Roles IAM mínimos, SGs estrictos. EC2 standalone sólo accesible por SSH desde la IP local del usuario.

 - A modo de simplificado, todas las EC2 tienen el mismo userdata. De esta manera es posible usar el Standalone EC2 para checkear el funcionamiento interno de los servicios Apache dado que estos no cuentan con acceso fuera del VPC.

 - User Data: Instala y habilita Apache, además del AWS CLI (este ultimo para probar el acceso del EC2 a los buckets corresponidentes).

 - Outputs: Se exponen datos útiles como DNS del ALB y Acceso por ssh al Standalone EC2 



## 6. Mejoras Potenciales
La propuesta de mejoras surge a partir de identificar ciertos gaps operativos en la solución inicial. Estos gaps representan funciones o controles faltantes que pueden comprometer la disponibilidad, seguridad y experiencia de usuario si no se abordan. Por ello, se plantea incorporar monitoreo proactivo y reforzar la seguridad del tráfico, asegurando así que la infraestructura no sólo cumpla los requisitos del challenge, sino que también sea resiliente y preparada para escenarios productivos reales.

#### 1. Alarmas y Monitoreo Proactivo

Actualmente, la infraestructura opera sin mecanismos automáticos de observabilidad. Una mejora inmediata sería la implementación de dashboards personalizados y alarmas en Amazon CloudWatch. Por ejemplo, configurar alertas ante altas tasas de error 5xx, baja disponibilidad de instancias, o uso inusual de recursos. Esto permitiría detectar incidentes o cuellos de botella antes de que impacten al usuario final, habilitando respuestas proactivas y reduciendo tiempos de caída.

#### 2. Acceso Seguro por HTTPS (TLS)

El entorno hoy expone el tráfico HTTP sin cifrado (puerto 80). Una mejora relevante sería modificar el ALB para soportar HTTPS, aplicando un certificado TLS gestionado (ACM). El listener HTTP (80) debe ser configurado para redirigir permanentemente a HTTPS (443), asegurando que todo el tráfico externo viaje cifrado. El listener en 443, a su vez, reenviaría las peticiones al target group backend. Esto no solo protege la información en tránsito, sino que también cumple mejores prácticas de seguridad y compliance.

## 7. Otros Gaps Operacionales Analizados
- El ASG no tiene acceso SSH directo, alineado a best practice, pero podría dificultar debugging rápido en ambientes reales.
- Cambios manuales de claves SSH o subredes requieren reprovisionamiento.
- La destrucción de la infra debe ser supervisada para evitar orfandad de recursos (por ejemplo, EIPs manuales).



## 8. Evidencia de Despliegue Exitoso
Adjunte screenshots de terraform apply, instancia EC2 con Apache corriendo, buckets S3, ALB online y otras piezas de evidencia que considero interesantes.





## 9. Comentarios y Notas del Challenge


Se optó por crear el target group del ASG fuera del módulo de ALB para tener flexibilidad total y outputs claros.

El troubleshooting de health checks en el ASG (unhealthy > healthy) requirió revisar tanto SG como routes/NAT gateways.

Se priorizó cumplir todos los requerimientos del enunciado utilizando modulos de terceros, recursos nativos del provider(AWS), y al menos 1 modulo de Coalfire.

El reto fue interesante especialmente al depurar issues con dependencias entre módulos, outputs no exportados y conportamientos de cada modulo. Este troubleshooting fue solucionado fragmentando la creacion de los servicios de cada modulo o servicio.

Se fragmento la creacion principalmente de los siguientes recursos:
 - VPC: Se fragmento la creacion de la vpc y del NAT para las subnets privadas.
 - ALB: Separamos la creacion del recursos principal de ALB, de los Target Groups y los listeners.



---------------

*Autor: Thomas Piñero*

---------------



