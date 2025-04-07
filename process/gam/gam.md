# GAM (Google Apps Manager) Resources

## Official Documentation
- [GAM Commands Documentation](https://sites.google.com/view/gam--commands/home?authuser=0)
- [GAM Wiki](https://github.com/GAM-team/GAM/wiki)
- [GAMADV-XTD3 Wiki](https://github.com/taers232c/GAMADV-XTD3/wiki)

## Tools

### OOO Message Setup Tool (`set_ooo.sh`)

A user-friendly tool for setting up Gmail Out-of-Office messages for departed employees.

#### Features
- Interactive command-line interface
- Support for preset values via command-line arguments
- Email format validation
- Message preview before setting
- Confirmation prompt

#### Usage

1. Interactive mode:
```bash
./set_ooo.sh
```

2. With preset values:
```bash
./set_ooo.sh -e user@example.com -c "Company Name" -n "John Doe" -m "contact@example.com"
```

3. Partial preset values:
```bash
./set_ooo.sh -e user@example.com -c "Company Name"
```

#### Command-line Options
- `-e, --email EMAIL`: User's email address (the departed employee)
- `-c, --company COMPANY`: Company name
- `-n, --name NAME`: Contact person's name
- `-m, --contact-email EMAIL`: Contact person's email
- `-h, --help`: Show help message

#### Example
```bash
# Set OOO message for a departed employee
./set_ooo.sh -e john.doe@company.com -c "Acme Corp" -n "Jane Smith" -m "jane.smith@company.com"
```

The tool will:
1. Validate all email addresses
2. Show a preview of the OOO message
3. Ask for confirmation before setting
4. Set the OOO message using GAM if confirmed