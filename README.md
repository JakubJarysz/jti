# From author 
Hello,

saddly I was not be able to finish the task in 100% due to lack of time and some knowledge gap between how I remember terraform (currently operating on bicep/arm templates). Anyway it was fun to back to work with terraform!

It was also my first time using github actions and workflows so also much to learn about that.

Im aware that it's end of my recruitment process for now but I would be glad to try again in the future because stack that JTI is using is cool and give a lot of oportunities to learn!

# JTI - Simple People Management API

A Flask-based REST API with Azure Infrastructure deployment using Terraform.

## Project Structure

```
├── .github/
│   └── workflows/
│       └── IaC.yml           # Terraform deployment pipeline
        └── Build-APP.yml           # Terraform deployment pipeline
├── App/
│   └── src/
│       ├── app.py           # Main Flask application
│       ├── db.py            # Database operations
│       ├── handlers.py      # API endpoints
│       └── swagger.py       # API documentation
|       └── app.dockerfile   # Simple Dockerfile to build
└── Infra/
    ├── env/
    │   ├── dev.tfvars      # Development variables
    │   ├── uat.tfvars      # UAT variables
    │   └── prd.tfvars      # Production variables
    |
    |   outputs.tf      # Output values
    |   variables.tf    # Variables definition
    |   main.tf         # Infrastructure configuration
    ├── backend.tf          # Terraform state configuration
    └── providers.tf        # Azure provider settings
```

## Application Components

### REST API Features

- **CRUD Operations for People Management**
  - Create new person records
  - Retrieve individual or all people
  - Delete person records
- **PostgreSQL Database Integration**
- **Swagger Documentation** at `/swagger`
- **Health Check Endpoint** at `/health`

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/people` | List all people |
| POST | `/api/people` | Create new person |
| GET | `/api/people/{id}` | Get person by ID |
| DELETE | `/api/people/{id}` | Delete person |

### Database Schema

```sql
CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Infrastructure as Code (IaC)

### Azure Resources
- Azure App Service
- Azure PostgreSQL Flexible Server
- Azure Storage Account (Terraform state)

### Deployment Pipeline

GitHub Actions workflow (`IaC.yml`) supports:
- Multiple environments (dev/uat/prd)
- Terraform validation
- Plan and apply stages
- Environment-specific approvals

## Local Development Setup

### Prerequisites
- Python 3.11+
- PostgreSQL
- Terraform 1.7.5
- Azure CLI

### Python Setup
```powershell
# Create and activate virtual environment
python -m venv .venv
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Environment Variables
```powershell
# Database configuration
$env:DB_HOST = "localhost"
$env:DB_NAME = "mydb"
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "your_password"
$env:DB_PORT = "5432"

# App configuration
$env:PORT = "8000"
```

### Running the Application
```powershell
# Start the Flask application
flask run --port=8000
```

### Infrastructure Deployment
```powershell
# Initialize Terraform
cd Infra
terraform init

# Plan deployment
terraform plan -var-file="env/dev.tfvars" -out=tfplan

# Apply changes
terraform apply tfplan
```

## API Usage Examples

### Create Person
```bash
curl -X POST http://localhost:8000/api/people \
  -H "Content-Type: application/json" \
  -d '{"first_name":"John","last_name":"Doe"}'
```

### Get All People
```bash
curl http://localhost:8000/api/people
```

### Get Person by ID
```bash
curl http://localhost:8000/api/people/1
```

### Delete Person
```bash
curl -X DELETE http://localhost:8000/api/people/1
```

## Environment Variables Reference

### Application
| Variable | Description | Default |
|----------|-------------|---------|
| DB_HOST | Database host | localhost |
| DB_NAME | Database name | mydb |
| DB_USER | Database username | postgres |
| DB_PASSWORD | Database password | password |
| DB_PORT | Database port | 5432 |
| PORT | Application port | 8000 |

### Infrastructure
| Variable | Description |
|----------|-------------|
| ARM_SUBSCRIPTION_ID | Azure subscription ID |
| ARM_TENANT_ID | Azure tenant ID |
| ARM_CLIENT_ID | Service principal ID |
| ARM_CLIENT_SECRET | Service principal secret |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request