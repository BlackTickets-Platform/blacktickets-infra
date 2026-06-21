$ErrorActionPreference = "Stop"

$imports = @(
    @{
        Address = 'module.ecr.aws_ecr_repository.service["frontend"]'
        Id      = "blacktickets-frontend"
    },
    @{
        Address = 'module.ecr.aws_ecr_repository.service["identity-service"]'
        Id      = "blacktickets-identity-service"
    },
    @{
        Address = 'module.ecr.aws_ecr_repository.service["event-service"]'
        Id      = "blacktickets-event-service"
    },
    @{
        Address = 'module.ecr.aws_ecr_repository.service["booking-service"]'
        Id      = "blacktickets-booking-service"
    },
    @{
        Address = 'module.ecr.aws_ecr_repository.service["chatbot-service"]'
        Id      = "blacktickets-chatbot-service"
    }
)

foreach ($item in $imports) {
    Write-Host "Importing $($item.Id) -> $($item.Address)"

    $arguments = @(
        "-chdir=terraform",
        "import",
        $item.Address,
        $item.Id
    )

    & terraform @arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform import failed for $($item.Id)"
    }
}
