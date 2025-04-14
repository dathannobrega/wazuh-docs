#!/bin/bash
# Variável com o nome da empresa
DATA_N="DataN"

# Variável do Wazuh Manager
WAZUH_MANAGER="soc.protexion.cloud"

# Mapeia o grupo do Wazuh Agent de acordo com a distribuição
get_wazuh_group() {
    case "$ID" in
        ubuntu)
            echo "Ubuntu,${DATA_N}"
            ;;
        debian)
            echo "Debian,${DATA_N}"
            ;;
        oracle)
            echo "Oracle,${DATA_N}"
            ;;
        fedora)
            echo "Fedora,${DATA_N}"
            ;;
        rhel)
            echo "RHEL,${DATA_N}"
            ;;
        opensuse*|sles)
            echo "Suse,${DATA_N}"
            ;;
        *)
            echo "Linux,${DATA_N}"
            ;;
    esac
}

# Função para instalar Sysmon no Ubuntu
install_ubuntu() {
    echo "Registrando chave e feed da Microsoft para Ubuntu..."
    UBUNTU_VERSION=$(lsb_release -rs)
    wget -q "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    echo "Atualizando repositórios..."
    sudo apt-get update
    echo "Instalando SysmonForLinux..."
    sudo apt-get install -y sysmonforlinux
}

# Função para instalar Sysmon no Debian
install_debian() {
    echo "Registrando chave e feed da Microsoft para Debian ${VERSION_ID}..."
    wget -q "https://packages.microsoft.com/config/debian/${VERSION_ID}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    echo "Atualizando repositórios..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https
    sudo apt-get update
    echo "Instalando SysmonForLinux..."
    sudo apt-get install -y sysmonforlinux
}

# Função para instalar Sysmon no Fedora
install_fedora() {
    echo "Registrando chave e feed da Microsoft para Fedora ${VERSION_ID}..."
    sudo rpm -Uvh "https://packages.microsoft.com/config/fedora/${VERSION_ID}/packages-microsoft-prod.rpm"
    echo "Instalando SysmonForLinux..."
    sudo dnf install -y sysmonforlinux
}

# Função para instalar Sysmon no RHEL
install_rhel() {
    echo "Registrando chave e feed da Microsoft para RHEL ${VERSION_ID}..."
    sudo rpm -Uvh "https://packages.microsoft.com/config/rhel/${VERSION_ID}/packages-microsoft-prod.rpm"
    echo "Instalando SysmonForLinux..."
    sudo dnf install -y sysmonforlinux
}

# Função para instalar Sysmon no openSUSE 15
install_opensuse() {
    echo "Registrando chave e feed da Microsoft para openSUSE 15..."
    sudo zypper install -y libicu
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    wget -q https://packages.microsoft.com/config/opensuse/15/prod.repo
    sudo mv prod.repo /etc/zypp/repos.d/microsoft-prod.repo
    sudo chown root:root /etc/zypp/repos.d/microsoft-prod.repo
    echo "Instalando SysmonForLinux..."
    sudo zypper install -y sysmonforlinux
}

# Função para instalar Sysmon no SLES 15
install_sles() {
    echo "Registrando chave e feed da Microsoft para SLES 15..."
    sudo rpm -Uvh https://packages.microsoft.com/config/sles/15/packages-microsoft-prod.rpm
    echo "Instalando SysmonForLinux..."
    sudo zypper install -y sysmonforlinux
}

# Função para configurar o Sysmon com as regras fornecidas
configure_sysmon() {
    echo "Configurando Sysmon com as regras especificadas..."
    # Cria o diretório caso não exista
    sudo mkdir -p /etc/sysmon
    sudo tee /etc/sysmon/sysmon.xml > /dev/null << 'EOF'
<Sysmon schemaversion="4.70">
  <EventFiltering>
    <!-- Event ID 1 == ProcessCreate. Log all newly created processes -->
    <RuleGroup name="" groupRelation="or">
      <ProcessCreate onmatch="exclude"/>
    </RuleGroup>
    <!-- Event ID 3 == NetworkConnect Detected. Log all network connections -->
    <RuleGroup name="" groupRelation="or">
      <NetworkConnect onmatch="exclude"/>
    </RuleGroup>
    <!-- Event ID 5 == ProcessTerminate. Log all processes terminated -->
    <RuleGroup name="" groupRelation="or">
      <ProcessTerminate onmatch="exclude"/>
    </RuleGroup>
    <!-- Event ID 9 == RawAccessRead. Log all raw access read -->
    <RuleGroup name="" groupRelation="or">
      <RawAccessRead onmatch="exclude"/>
    </RuleGroup>
    <!-- Event ID 10 == ProcessAccess. Log all open process operations -->
    <RuleGroup name="" groupRelation="or">
      <ProcessAccess onmatch="exclude"/>
    </RuleGroup>
    <!-- Event ID 11 == FileCreate. Log every file creation -->
    <RuleGroup name="" groupRelation="or">
      <FileCreate onmatch="exclude">
            <TargetFilename condition="begin with">/opt/splunkforwarder/var/lib/splunk/modinputs/journald</TargetFilename> <!--Exclude Splunk Modinput Journal-->
      </FileCreate>
    </RuleGroup>
    <!-- Event ID 23 == FileDelete. Log all files being deleted -->
    <RuleGroup name="" groupRelation="or">
      <FileDelete onmatch="exclude"/>
    </RuleGroup>
  </EventFiltering>
</Sysmon>
EOF
    echo "Arquivo de configuração do Sysmon salvo em /etc/sysmon/sysmon.xml"
}

# Função para instalar o Wazuh Agent (para sistemas baseados em apt/deb)
install_wazuh_apt() {
    echo "Instalando Wazuh Agent (apt/deb)..."
    wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.11.1-1_amd64.deb
    WAZUH_GROUP=$(get_wazuh_group)
    sudo WAZUH_MANAGER="${WAZUH_MANAGER}" WAZUH_AGENT_GROUP="${WAZUH_GROUP}" dpkg -i ./wazuh-agent_4.11.1-1_amd64.deb
}

# Função para instalar o Wazuh Agent (para sistemas baseados em rpm)
install_wazuh_rpm() {
    echo "Instalando Wazuh Agent (rpm)..."
    curl -o wazuh-agent-4.11.1-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.1-1.x86_64.rpm
    WAZUH_GROUP=$(get_wazuh_group)
    sudo WAZUH_MANAGER="${WAZUH_MANAGER}" WAZUH_AGENT_GROUP="${WAZUH_GROUP}" rpm -ihv wazuh-agent-4.11.1-1.x86_64.rpm
}

# Carrega informações do sistema
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Arquivo /etc/os-release não encontrado. Não é possível identificar o sistema operacional."
    exit 1
fi

echo "Distribuição identificada: $ID $VERSION_ID"

# Instalação do Sysmon conforme a distribuição
case "$ID" in
    ubuntu)
        if [[ "$VERSION_ID" == "20.04" || "$VERSION_ID" == "22.04" || "$VERSION_ID" == "23.04" ]]; then
            install_ubuntu
        else
            echo "Versão do Ubuntu não suportada por este script."
            exit 1
        fi
        ;;
    debian)
        if [[ "$VERSION_ID" == "11" || "$VERSION_ID" == "12" ]]; then
            install_debian
        else
            echo "Versão do Debian não suportada por este script."
            exit 1
        fi
        ;;
    fedora)
        if [[ "$VERSION_ID" == "37" || "$VERSION_ID" == "38" ]]; then
            install_fedora
        else
            echo "Versão do Fedora não suportada por este script."
            exit 1
        fi
        ;;
    rhel)
        if [[ "$VERSION_ID" == "8" || "$VERSION_ID" == "9" ]]; then
            install_rhel
        else
            echo "Versão do RHEL não suportada por este script."
            exit 1
        fi
        ;;
    opensuse* )
        # Considera openSUSE 15
        install_opensuse
        ;;
    sles)
        # Considera SLES 15
        install_sles
        ;;
    *)
        echo "Distribuição não suportada por este script."
        exit 1
        ;;
esac

# Configura as regras do Sysmon
configure_sysmon

# Instalação do Wazuh Agent de acordo com a base do sistema (apt ou rpm)
case "$ID" in
    ubuntu|debian|oracle)
        install_wazuh_apt
        ;;
    fedora|rhel|opensuse*|sles)
        install_wazuh_rpm
        ;;
    *)
        echo "Não foi possível determinar o método de instalação do Wazuh Agent para esta distribuição."
        exit 1
        ;;
esac
