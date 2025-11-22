#!/bin/bash

# Configuración OCI
TENANCY_OCID="ocid1.tenancy.oc1..aaaaaaaafwdjaijilkfvc37n27ki626n2v5tew5nfqsqmsbtcq7qnbwwrp5a"
USER_OCID="ocid1.user.oc1..aaaaaaaayh4gi5uw62nwcemruqq7ejk3hf2me274ervncgkixi2nywl4jfja"
FINGERPRINT="f7:86:c8:7c:f4:d8:06:98:b0:33:25:f3:ae:a2:1d:1c"
REGION="sa-bogota-1"
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq"

# Configurar OCI CLI
mkdir -p ~/.oci
cat > ~/.oci/config << EOF
[DEFAULT]
user=$USER_OCID
fingerprint=$FINGERPRINT
tenancy=$TENANCY_OCID
region=$REGION
key_file=~/.oci/oci_api_key.pem
EOF

cat > ~/.oci/oci_api_key.pem << 'EOF'
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCh0/1sNxG50Ruo
vgZ296HlV12U3z/V7unbQ+DWo8wf4RLKueLRGKl3ZSakbpyRoAl1kw6GvtTPZI/V
K4r+ahJ2GJZ8cnlnvSqo/dOY1aHZRDxufhaK2XC1TRutVwmTpoJIzxK8VSc4Guia
GGjDVL6p6if0g/M89iDlfaxmQbP2P3zVK8KpekzG9bB6zPI1P0v9wmIhw4A4I+yL
Je18K79AJS1QfAFTmyR7AqOOc43GkBRCIX5Qj+nv+TcKenqa121+aArHDuWlOwKk
gU6v1ppKmae2lty/qwy4Clwfgg32PdcjVwp2OGr4tbzNhIXdYl0DufsAEnMD9hpP
X3xgcsa9AgMBAAECggEAS9tj2VStFfXL6dr9i8nDlY5Q+yZ1NXKzI4mbfPG2DyGB
ng7poAtX8PQ023JQKUEj/f2rmwUcG4VvmMS6+Ew/kCUxcW91smetdh7Zj7RglEhU
rZSkO3z2xL264hPBFPnB66BJj4e5BScz7nvPq/RvFZYCGa+6ltJnFDxHUn2s/pn/
jDPzB1pVV88zUOhTrBr7Q6+XuG+qDIma4TGQ34ekClfj1mTQV6PXbLF80ZAJH18y
egfjVAQLZGDNDSJCJu1LgEUHbeqXc/8UyLHkeVm1MfKtxuL5oKzC20YVXR9egrAR
fbAriQDceUs+zOxQNKXrPtm54H0cTltT5Xcd2GbIfwKBgQDdUVOsVmo9pNgshAnS
v77p5TkZA3KAttto9rC0E/WOMSgkQ/t86OnBllHBsJ8eLOH6ABQ7eNBsUZWcC5q/
bGoYRaoMHbJP3FYejxmD/+I5zPo7U3v/IuzpwQV03wvijVoci9czC6/rkBzFMZG6
ycDwaWfI0pP1ZDvUlfHIMLNTowKBgQC7MBmCW5FicXaxMQKTSn8q6XnJYfyyBXE8
HskH2UfS9/Kc+SWbwikpuR8eLom+cyYdR/Ps2WDSee8UKj3StneLu5PJFF46Uq/6
Gx/swn6UFZvb7BnB2me3hlNeGSCA0PIPe+6Lz8/DbVEDcN+HrqkLuzdz7/Y9kBBz
wjYsSeAiHwKBgE+v0a3Sq4woh4F3xUWxrp7u3uEnwZmgvV2MvVEJgrfA8VAlfi6a
elgutJ9F5fTqei8WyjIjrP/jXDgEYaKc+ZJluvWD18kzb3qvUaOaha0EJfEofRP/
UkhULI/JI7Fd7d0raL/DbIMnr4Q89djIfgTSHwFK+OU5QuWnW5gWGOt7AoGAQrLI
5CIsk59KY6jK+iC5X1kCBDfeCrDVwE5X42wQo6Ol1zkPpYhxkmRcKiz699mf4x8Y
U3TBgz3fapgCn2pU/n1AE44mZTHBcqTnoz1KTQnGF37xTpm8CzDZ09WwNzY8ijfm
r/rEVSZGj6tQetBJe9yhzbXbT+RdeGHjW7SXIJECgYAVipiFPXGdS4uzW4il8d+9
EYveZXBT5zmVOx6jGH+2D77nRpV0cTOHehK8foqeo/nftm1epkx4MeLAbBR6eVel
2rpB3c9HWhC0GqYN8raXPGdewxEF2hT90vEqCmb8XnwGNj/SV31FUC9dKK2M2kqr
XXytwZg8FJspi0sT69QuPg==
-----END PRIVATE KEY-----
EOF

chmod 600 ~/.oci/oci_api_key.pem
chmod 600 ~/.oci/config

echo "🔍 Listando vaults en el compartment..."

# Listar todos los vaults activos con --all para obtener todos los resultados
oci kms management vault list --compartment-id "$COMPARTMENT_ID" --all --query "data[?\"lifecycle-state\"=='ACTIVE'].{id:id,name:\"display-name\",created:\"time-created\"}" --output table

echo ""
echo "📋 Obteniendo IDs de vaults para eliminar..."

# Obtener todos los vault IDs ordenados por fecha (más antiguo primero) y saltar el más reciente
VAULT_IDS=$(oci kms management vault list --compartment-id "$COMPARTMENT_ID" --all --query "data[?\"lifecycle-state\"=='ACTIVE'] | sort_by(@, &\"time-created\") | [:-1].id" --raw-output 2>/dev/null)

if [ -z "$VAULT_IDS" ] || [ "$VAULT_IDS" = "null" ] || [ "$VAULT_IDS" = "[]" ]; then
    echo "✅ Solo hay un vault o ninguno. No hay nada que eliminar."
    exit 0
fi

echo "🗑️ Eliminando vaults antiguos..."
echo "Vaults a eliminar: $VAULT_IDS"

for VAULT_ID in $VAULT_IDS; do
    if [ "$VAULT_ID" != "null" ] && [ -n "$VAULT_ID" ]; then
        echo "Eliminando vault: $VAULT_ID"
        
        # Programar eliminación del vault (requiere tiempo de espera) - macOS compatible
        DELETION_TIME=$(date -u -v+7d +%Y-%m-%dT%H:%M:%S.000Z)
        oci kms management vault schedule-deletion --vault-id "$VAULT_ID" --time-of-deletion "$DELETION_TIME" --force
        
        if [ $? -eq 0 ]; then
            echo "✅ Vault $VAULT_ID programado para eliminación"
        else
            echo "❌ Error eliminando vault $VAULT_ID"
        fi
    fi
done

echo "🎉 Limpieza completada. Solo queda el vault más reciente."