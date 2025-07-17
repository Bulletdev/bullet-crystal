#  🐓 Rinha de Backend 2025 - Crystal

 <div>

                   ⢀⣴⣿⣿⣿⣿⣿⣶⣶⣶⣿⣿⣶⣶⣶⣶⣶⣿⡿⣿⣾⣷⣶⣶⣾⣿⠀                                                                                                                          
                 ⣠⣿⣿⢿⣿⣯⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⡇⣿⣿⣿⣿⣿⡇                                                                                                     
             ⠀⣰⣿⣿⣷⡟⠤⠟⠁⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⡇⣿⣿⣿⣿⣿⡇ 
             ⠀⣿⣿⣿⣿⣿⣷⣶⣿⣿⡟⠁⣮⡻⣿⣿⣿⣿⣿⣿⣿⣿⢸⡇⣿⣿⣿⣿⣿⡇ 
             ⠘⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⣿⣿⣹⣿⣿⣿⣿⣿⣿⡿⢸⡇⣿⣿⣿⣿⣿⡇ 
             ⠀⠙⢿⣿⣿⣿⡿⠟⠁⣿⣿⣶⣿⠟⢻⣿⣿⣿⣿⣿⣿⡇⣼⡇⣿⣿⣿⣿⣿⠇
             ⠀⠀⠈⠋⠉⠁⣶⣶⣶⣿⣿⣿⣿⢀⣿⣿⣿⣿⣿⣿⣿⣇⣿⢰⣿⣿⣿⣿⣿⠀ 
             ⠀⠀⠀⠀⠀⠙⠿⣿⣿⣿⡄⢀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣽⣿⣼⣿⣿⣿⣿⠇⠀ 
             ⠀⠀⠀⠀⠀⠀⠀⠈⠉⠒⠚⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠛⠿⠿⠿⠿⠿⠋⠀⠀ 
             ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
             ⠀⠀⠀⣿⣙⡆⠀⠀⡇⠀⢸⠀⠀⢸⠀⠀ ⢸⡇⠀⠀⢸⣏⡉  ⠙⡏⠁⠀ 
             ⠀⠀⠀⣿⣉⡷⠀⠀⢧⣀⣼ ⠀⢸⣀  ⢸⣇⡀ ⢸⣏⣁⠀ ⠀⡇⠀ 

             
  </div>
  

## 📋 Stack Utilizada

- **Crystal**: Linguagem de programação de alta performance
- **PostgreSQL**: Armazenamento de dados de pagamentos
- **Redis**: Cache para otimização de health checks
- **Nginx**: Load balancer com round-robin
- **Docker**: Containerização completa

##  Como Executar

### 1. Subir os Payment Processors
```bash
# Primeiro, suba os payment processors
docker-compose -f docker-compose.yml up -d
```

### 2. Subir o Backend
```bash
# Depois, suba o backend
docker-compose up -d
```

### 3. Acessar a API
A API estará disponível em `http://localhost:9999`

##  Endpoints da API

 <details align="left">

### POST `/payments`

Intermedia uma solicitação de pagamento para os Payment Processors.

**Corpo da Requisição:**
```json
{
  "correlationId": "4a7901b8-7d26-4d9d-aa19-4dc1c7cf60b3",
  "amount": 19.90
}
```

**Campos:**
- `correlationId`: UUID único obrigatório
- `amount`: Valor decimal obrigatório (maior que 0)

**Respostas:**
- `200 OK`: Pagamento processado com sucesso
- `400 Bad Request`: Dados de entrada inválidos
- `500 Internal Server Error`: Erro no processamento

### GET `/payments-summary`

Retorna resumo dos pagamentos processados, usado para auditoria.

**Parâmetros de Query (opcionais):**
- `from`: Timestamp ISO em UTC (ex: `2020-07-10T12:34:56.000Z`)
- `to`: Timestamp ISO em UTC (ex: `2020-07-10T12:35:56.000Z`)

**Exemplo de Uso:**
```
GET /payments-summary?from=2020-07-10T12:34:56.000Z&to=2020-07-10T12:35:56.000Z
```

**Resposta (200 OK):**
```json
{
  "default": {
    "totalRequests": 43236,
    "totalAmount": 415542345.98
  },
  "fallback": {
    "totalRequests": 423545,
    "totalAmount": 329347.34
  }
}
```

### POST `/purge-payments`  

Endpoint secreto utilizado pelo script de teste da Rinha para limpar todos os pagamentos do banco. Não requer corpo na requisição.

**Exemplo de Uso:**
```
curl -X POST http://localhost:9999/purge-payments
```

**Resposta (200 OK):**
```json
{"result": "ok"}
```
</details>

### Limites de Memória

- API 1: 70MB
- API 2: 70MB
- PostgreSQL: 180MB
- Nginx: 20MB
- **Total: 340MB** (dentro do limite de 350MB)
