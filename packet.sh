#!/bin/bash

# Renkler
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
RED='\033[0;31m'
BLUE='\033[0;34m'


banner() {
  
  echo -e "${GREEN}"
  echo "╔═════════════════════════════════════════════╗"
  echo "║     Linux Paket Kurulum Aracı (v1.0)       ║"
  echo "╚═════════════════════════════════════════════╝"
  echo -e "${NC}"
}

kur_programlar() {
  apt update
  for paket in "$@"; do
    echo -e "\n${YELLOW}Kuruluyor: $paket${NC}"
    apt install -y "$paket"
  done
}



paket_durumunu_goster() {
  echo -e "\n${YELLOW}Paket Durumları:${NC}"
  for paket in "$@"; do
    if dpkg -s "$paket" &>/dev/null; then
      surum=$(dpkg -s "$paket" | grep '^Version:' | awk '{print $2}')
      echo -e "  $paket: ${GREEN}Yüklü${NC} (Sürüm: $surum)"
    else
      echo -e "  $paket: ${RED}Yüklü değil${NC}"
    fi
  done
  echo ""
  read -p "Devam etmek için Enter'a basın..."
}



kurulu_paketler() {
  banner
  echo -e "${YELLOW}Kurulu Tüm Paketler${NC}"
  echo "1) Ekrana yazdır"
  echo "2) Dosyaya kaydet (~/kurulu_paketler.txt)"
  echo "3) Geri dön"
  read -p "#? " secim
  case $secim in
    1)
     dpkg-query -W -f='${binary:Package} ${Version}\n' | sort
     ;;
    2)
      dpkg-query -W -f='${binary:Package} ${Version}\n' | sort > ~/kurulu_paketler.txt
      echo -e "\n${GREEN}Liste kaydedildi: ~/kurulu_paketler.txt${NC}"
      ;;
    3) return ;;
    *) echo "Geçersiz seçim!" ; sleep 1 ;;
  esac
}


sil_programlar() {
  for paket in "$@"; do
    echo -e "\n${YELLOW}Kaldırılıyor: $paket${NC}"
    apt remove --purge -y "$paket"
  done
}

surum_kur() {
  read -p "Paket adı: " paket
  echo -e "\n${YELLOW}Mevcut Sürümler:${NC}"
  apt list -a "$paket" 2>/dev/null | grep -v "Listing..."
  echo ""
  read -p "Kurulacak tam sürüm (örnek: 1.14.2-1): " surum
  apt install -y "${paket}=${surum}"
}

stats(){
	while true; do
	    clear
	    statss
	    sleep 1
	done
}

statss() {
  print_header() {
    echo -e "\n${YELLOW}==================== $1 ====================${NC}"
  }

  print_header "CPU Kullanımı"
  mpstat | awk '/Average/ && $3 ~ /[0-9.]+/ {print "Toplam CPU Kullanımı: "100 - $13"%"}'

  print_header "Bellek Kullanımı"
  free -h
  echo
  free | awk '/Mem/ {
      used=$3; total=$2;
      printf("Bellek Kullanımı: %.2f%%\n", used/total * 100)
  }'

  print_header "Disk Kullanımı"
  df -h --total | grep total
  echo
  df --total | awk '/total/ {
      used=$3; total=$2;
      printf("Disk Kullanımı: %.2f%%\n", used/total * 100)
  }'

  print_header "CPU'ya Göre En Yoğun 5 Süreç"
  ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6

  print_header "Belleğe Göre En Yoğun 5 Süreç"
  ps -eo pid,comm,%mem --sort=-%mem | head -n 6

  print_header "Sistem Bilgileri"
  echo "İşletim Sistemi: $(uname -a)"
  echo "Çalışma Süresi: $(uptime -p)"
  echo "Yük Ortalaması: $(uptime | awk -F'load average:' '{ print $2 }')"
  echo -e "\nGiriş Yapan Kullanıcılar:"
    print_header "Giriş Yapan Kullanıcılar"
{
  echo "Kullanıcı Terminal Giriş_Saati Oturum_Süresi Boşta CPU_Kullanımı Komut"
  w -h | while read user tty from login idle jcpu pcpu cmd; do
    echo "$user $tty $login $idle $jcpu $pcpu $cmd"
  done
} | column -t

  print_header "SSH Hatalı Giriş Denemeleri"
  journalctl _COMM=sshd | grep "Failed password" | tail -n 5

  echo -e "\n${YELLOW}==================== Rapor Sonu ====================${NC}"
  
  read -t 0.01 -p "CIKMAK ICIN 'Y' BAS " cikis
  if [[ "${cikis,,}" == "y" ]]; then
    exit
  fi
  echo "" 
  echo "Devam ediliyor..." 
}

menu_secimi() {
  local baslik="$1"
  shift
  local gorunenler=() 
  local paketler=()
  local i=1

  while [[ $1 != "__END__" ]]; do
    gorunenler+=("$1")
    shift
    paketler+=("$1")
    shift
  done

  local ekstra_secenekler=(
    "Tümünü Kur"
    "Sürüm Belirleyerek Kur"
    "${RED}Tümünü Sil${NC}"
    "${RED}Belirleyerek Sil${NC}"
    "Paket Durumlarını Göster"
    "${BLUE}Geri${NC}"
  )



  while true; do
    banner
    echo -e "${YELLOW}→ $baslik${NC}"
    for ((i=0; i<${#gorunenler[@]}; i++)); do
      echo "$((i+1))) ${gorunenler[$i]}"
    done
    for ((j=0; j<${#ekstra_secenekler[@]}; j++)); do
      echo -e "$((i+j+1))) ${ekstra_secenekler[$j]}"
    done
    echo ""
    read -p "#? " secim

    if [[ $secim -ge 1 && $secim -le ${#gorunenler[@]} ]]; then
      kur_programlar "${paketler[$((secim-1))]}"
      continue
    fi

    case $secim in
      $((i+1))) kur_programlar "${paketler[@]}" ;;
      $((i+2))) sil_programlar "${paketler[@]}" ;;
      $((i+3))) surum_kur ;;
      $((i+4)))
        echo -e "\nBelirlemek için tekrar numara girin (virgülle ayırarak):"
        for ((k=0; k<${#gorunenler[@]}; k++)); do
          echo "$((k+1))) ${gorunenler[$k]}"
        done
        read -p "Silinecek numaralar: " numaralar
        for num in $(echo $numaralar | tr ',' ' '); do
          sil_programlar "${paketler[$((num-1))]}"
        done
        ;;
      $((i+5))) paket_durumunu_goster "${paketler[@]}" ;;
      $((i+6))) break ;;

      *) echo "Geçersiz seçim!" ; sleep 1 ;;
    esac
    sleep 1
  done
}



guvenlik_araclari() {
  menu_secimi "Güvenlik Araçları" \
    "ufw (Firewall)" ufw \
    "fail2ban (SSH brute-force koruması)" fail2ban \
    "rkhunter (Rootkit tarayıcı)" rkhunter \
    "clamav (Antivirüs)" clamav \
    __END__
}

ag_araclari() {
  menu_secimi "Ağ Araçları" \
    "net-tools (ifconfig vb.)" net-tools \
    "nmap (Port tarayıcı)" nmap \
    "traceroute (Yol izleme)" traceroute \
    "iperf3 (Hız testi)" iperf3 \
    __END__
}


web_sunucusu() {
  menu_secimi "Web Sunucusu" \
    "apache2" apache2 \
    "nginx" nginx \
    "php" php \
    "mysql-server" mysql-server \
    __END__
}

gelistirme_araclari() {
  menu_secimi "Geliştirme Araçları" \
    "git (Versiyon kontrol sistemi)" git \
    "build-essential (Derleyici araçları)" build-essential \
    "python3 (Python yorumlayıcısı)" python3 \
    "python3-pip (Python paket yöneticisi)" python3-pip \
    "python3-venv (Sanal ortam yöneticisi)" python3-venv \
    "docker.io (Docker altyapısı)" docker.io \
    "docker-compose (Docker bileşen yöneticisi)" docker-compose \
    __END__
}


# Ana Menü
while true; do
  banner
  echo -e "\n  ${YELLOW}— Ana Menü —${NC}"
  echo ""
  echo "  1) Güvenlik Araçları"
  echo "  2) Ağ Araçları"
  echo "  3) Web Sunucusu"
  echo "  4) Geliştirme Araçları"
  echo "  5) Sistem İstatistikleri"
  echo "  6) Kurulu Paketleri Listele"
  echo -e "  7) ${BLUE}Çıkış ${NC}"
  echo ""
  read -p "  Seçiminiz: " secim
  case $secim in
    1) guvenlik_araclari ;;
    2) ag_araclari ;;
    3) web_sunucusu ;;
    4) gelistirme_araclari ;;
    5) stats ;;
    6) kurulu_paketler ;;
    7) exit ;;
    *) echo "Geçersiz seçim!" ; sleep 1 ;;
  esac
  sleep 1
  banner
done

