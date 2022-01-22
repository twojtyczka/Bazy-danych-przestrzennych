import fme
import smtplib
import ssl
from datetime import datetime

now = datetime.now()
timestamp = now.strftime("%H:%M:%S %Y-%m-%d")
email = fme.macroValues['email']
email2 = fme.macroValues['client_email']
password = fme.macroValues['password']
powiat = fme.macroValues['powiat']
context = ssl.create_default_context()
port = 465

def send_email(sender_email, email2, message ):
    with smtplib.SMTP_SSL("smtp.gmail.com", port, context=context) as server:
        server.login(email, password)
        server.sendmail(sender_email, email2, message)

message_content = """\
Subject: Drogi uzytkowniku {0}, o godzinie {1} rozpoczeto przetwarzanie danych dla powiatu {2}."""
message = message_content.format(email2, timestamp, powiat)
send_email(email, email2, message,)
