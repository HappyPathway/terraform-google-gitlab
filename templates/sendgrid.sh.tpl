/usr/bin/curl --request POST \
--url https://api.sendgrid.com/v3/mail/send \
--header 'Authorization: Bearer ${smtp_password}' \
--header 'Content-Type: application/json' \
--data '
{
    "personalizations": [
        {
            "to": [
                {"email": "${email}"}
            ]
        }
    ],
    "from": {"email": "${email}"},
    "subject": "Hello, World!",
    "content": [
        {"type": "text/plain", "value": "Heya!"}
    ]
}'