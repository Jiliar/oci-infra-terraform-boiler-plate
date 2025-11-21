# OCI Authentication
tenancy_ocid   = "ocid1.tenancy.oc1..aaaaaaaafwdjaijilkfvc37n27ki626n2v5tew5nfqsqmsbtcq7qnbwwrp5a"
user_ocid      = "ocid1.user.oc1..aaaaaaaayh4gi5uw62nwcemruqq7ejk3hf2me274ervncgkixi2nywl4jfja"
fingerprint    = "f7:86:c8:7c:f4:d8:06:98:b0:33:25:f3:ae:a2:1d:1c"
private_key    = <<EOF
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
region         = "sa-bogota-1"

# Cluster ID from main infrastructure
cluster_id = "ocid1.cluster.oc1.sa-bogota-1.aaaaaaaayzacl6pbhbd7ymujuhdxxw44ywuqnjjklfs6ez4nmcmscnow7i4a"

# Istio Configuration
istio_version                    = "1.20.0"
enable_gateway                   = true
gateway_name                     = "addon-ai-dev-gateway"
gateway_namespace                = "default"
gateway_hosts                    = ["dev.addon-ai.com"]
enable_virtualservice            = true
virtualservice_name              = "addon-ai-dev-vs"
virtualservice_namespace         = "default"
virtualservice_hosts             = ["dev.addon-ai.com"]
virtualservice_destination_host  = "addon-ai-dev-service"
virtualservice_destination_port  = 80
enable_peer_authentication       = true
mtls_mode                        = "STRICT"

# TLS/SSL Configuration (Cert-Manager)
enable_tls                       = true
enable_https_redirect            = true
tls_secret_name                  = "dev-addon-ai-tls"  # Cert-Manager creará este secret