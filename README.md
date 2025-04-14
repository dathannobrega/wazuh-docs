# 🛡️ Wazuh CI/CD & Regras Personalizadas

Este repositório contém minha estrutura de automação (CI/CD) para implantar e manter o Wazuh, além de um conjunto de regras personalizadas que expandem a capacidade de detecção do sistema.

## 📦 Conteúdo

- `ci/` – Scripts e pipelines de CI/CD para instalação, atualização e verificação dos serviços Wazuh.
- `rules/local_rules.xml` – Arquivo com regras personalizadas (IDS/IPS).
- `decoders/` – Decodificadores específicos criados para logs customizados.
- `agents/` – Exemplos de configurações de agentes e templates.
- `scripts/` – Ferramentas auxiliares para automação, debug e healthcheck.
- `docs/` – Documentação interna e instruções para novos colaboradores/admins.

## 🚀 Objetivo

- Automatizar a instalação/configuração do Wazuh Manager, Indexer e Dashboard.
- Manter versões personalizadas e testadas de regras e decoders.
- Permitir integração com pipelines GitLab/GitHub Actions para validar regras e aplicar atualizações automaticamente.
- Garantir versionamento e rastreabilidade das regras utilizadas em produção.

## 🛠️ Requisitos

- Linux com systemd
- Acesso root (para aplicar mudanças)
- Git
- Docker ou ambiente com Wazuh instalado
- (Opcional) GitLab Runner ou GitHub Actions configurados

## ✅ Pipeline de exemplo

```yaml
# Exemplo para GitLab CI (.gitlab-ci.yml)
stages:
  - validate
  - deploy

validate-rules:
  stage: validate
  script:
    - ./scripts/validate-rules.sh

deploy-wazuh-config:
  stage: deploy
  script:
    - ./scripts/deploy-to-wazuh.sh
  only:
    - main
