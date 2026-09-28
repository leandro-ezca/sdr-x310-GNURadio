# SDR X310 — GNU Radio + UHD 4.10 en Docker

Entorno listo para usar la **USRP X310** con **GNU Radio**, usando **UHD 4.10**,
la misma versión de las imágenes FPGA cargadas en la radio.

## Qué incluye

| Componente | Versión | Cómo se instala |
|---|---|---|
| Ubuntu | 24.04 | Imagen base |
| UHD | 4.10.0.0 | Compilado desde el repo de Ettus |
| GNU Radio | 3.10.12.0 | Compilado contra UHD 4.10 |
| Imágenes FPGA X310 | 4.10 (HG y XG) | `uhd_images_downloader` |

UHD y GNU Radio se compilan porque en Ubuntu `apt` instala UHD 4.6, que no es
compatible con las imágenes 4.10 de la radio. El build se corta si la versión
de UHD, o la que usa GNU Radio, no es 4.10.

## Requisitos

- PC con **Linux** (probado en Ubuntu 24.04) y procesador x86_64.
- **Docker** con el plugin `compose`.
- Placa de red Ethernet conectada al **puerto 0** de la X310.

## Configuración de la PC (una sola vez)

### 1. Docker

```bash
sudo apt install docker.io docker-compose-v2 docker-buildx
sudo usermod -aG docker $USER
sudo reboot
```

Para verificar: `docker ps` no tiene que dar *permission denied*.

### 2. IP fija de la placa de red

En **Configuración → Red → Cableada → IPv4 → Manual**:

- Dirección: `192.168.10.1`
- Máscara: `255.255.255.0`

La X310 usa por defecto `192.168.10.2` en el puerto 0.

### 3. Buffers de red

```bash
echo -e "net.core.rmem_max=33554432\nnet.core.wmem_max=33554432" | sudo tee /etc/sysctl.d/60-usrp.conf
sudo sysctl --system
```

## Instalación

```bash
git clone <URL-del-repo>
cd sdr-x310
./sdr.sh build
```

La primera vez tarda bastante (se compilan UHD y GNU Radio). Las siguientes
son instantáneas.

## Uso

| Comando | Qué hace |
|---|---|
| `./sdr.sh grc` | Abre GNU Radio Companion |
| `./sdr.sh find` | Busca la X310 en la red |
| `./sdr.sh probe` | Muestra el detalle de la X310 (FPGA, daughterboards) |
| `./sdr.sh shell` | Terminal dentro del contenedor (se sale con `exit`) |

Si la radio tiene otra IP:

```bash
USRP_ADDR=192.168.40.2 ./sdr.sh find
```

### Carpetas

| En la PC | En el contenedor | Uso |
|---|---|---|
| `capturas/` | `/capturas` | Archivos de muestras |
| `flowgraphs/` | `/flowgraphs` | Flowgraphs `.grc` |

## Volver a cargar la imagen FPGA 4.10 en la radio

Si alguien le cargó a la X310 otra versión (por ejemplo, desde MATLAB):

```bash
./sdr.sh shell
uhd_image_loader --args "type=x300,addr=192.168.10.2,fpga=HG"
exit
```

Después hay que **apagar y prender** la radio. No hay que cortarlo mientras carga.

## Problemas comunes

| Error | Solución |
|---|---|
| `permission denied ... docker.sock` | El usuario no está en el grupo `docker`, o falta reiniciar. |
| `cannot open display` | Ejecutar con `./sdr.sh grc`, que da el permiso de pantalla. |
| `Major compat number mismatch` | La radio tiene imágenes de otra versión de UHD. Ver la sección anterior. |
| `uhd_find_devices` no encuentra nada | Revisar el cable, la IP fija y que la radio esté encendida (`ping 192.168.10.2`). |
