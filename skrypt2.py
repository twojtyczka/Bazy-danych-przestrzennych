from datetime import datetime
from email.mime.multipart import MIMEMultipart 
from email.mime.text import MIMEText 
from email.mime.application import MIMEApplication
import fme
import smtplib
import ssl
import os
import json

now = datetime.now()
timestamp = now.strftime("%H:%M:%S %Y-%m-%d")
email = fme.macroValues['email']
email2 = fme.macroValues['client_email']
password = fme.macroValues['password']
proc_duration = str(round(fme.elapsedRunTime, 0))
powiat = fme.macroValues['powiat']
rozpoczecie = fme.macroValues['start_date']
koniec =  fme.macroValues['end_date']
pokrycie =  fme.macroValues['cloud']
port = 465
context = ssl.create_default_context()

def send_email(sender_email, email2, message ):
    with smtplib.SMTP_SSL("smtp.gmail.com", port, context=context) as server:
        server.login(email, password)
        server.sendmail(sender_email, email2, message)

def create_log_file(powiat, rozpoczecie, koniec, pokrycie):
    dictionary = {
    "powiat" : powiat,
    "data_rozpoczecia" : rozpoczecie,
    "data_zakonczenia"  : koniec,
    "pokrycie_chmurami" : pokrycie
    }
    json_log = json.dumps(dictionary, indent=4)
    with open(jsonPath, "w") as outfile:
        outfile.write(json_log)
    
message = MIMEMultipart('mixed')
message['From'] = 'Contact <{sender}>'.format(sender = email)
message['To'] = email2
file_name = powiat + r".tif"
attachmentPath = os.path.join(r"C:\Users\ASUS\Desktop\writer" , file_name)
jsonPath = os.path.join(r"C:\Users\ASUS\Desktop\writer" , "log.geojson")
status = fme.status
if status == 0:
    create_log_file(powiat, rozpoczecie, koniec, pokrycie)
    message['Subject'] = 'Przetwarzanie zakonczylo sie bledem.'
    msg_content = """
    <h3>W przetwarzaniu danych dla powiatu {0} wystapil blad. Blad: brak zobrazowan dla parametrow przeslanych w zalaczniku.
    """.format(powiat)
    body = MIMEText(msg_content, 'html')
    message.attach(body)
    try:
        with open(jsonPath, "rb") as attachment:
            p = MIMEApplication(attachment.read(),_subtype="json")
            p.add_header('Content-Disposition', "attachment; filename= %s" % jsonPath.split("\\")[-1])
            message.attach(p)
    except Exception as e:
	    print(str(e))

else:
    srednia =  round(fme.macroValues['mean'], 3)
    odchylenie =  round(fme.macroValues['stdev'], 3)
    message['Subject'] = 'Przetwarzanie zakonczylo sie sukcesem.'
    msg_content = """
    <h3>Zakonczylo sie przetwarzanie danych dla powiatu {0}.</h3> <br>
    Czas trwania: {1} s
    Zestawienie statystyk rastra:
    <ul>
    <li>Srednia: {2}</li>
    <li>Odchylenie standardowe: {3}</li>
    </ul>
    """.format(powiat, proc_duration, str(srednia), str(odchylenie))
    body = MIMEText(msg_content, 'html')
    message.attach(body)
    try:
        with open(attachmentPath, "rb") as attachment:
            p = MIMEApplication(attachment.read(),_subtype="tif")
            p.add_header('Content-Disposition', "attachment; filename= %s" % attachmentPath.split("\\")[-1])
            message.attach(p)
    except Exception as e:
	    print(str(e))

print(proc_duration)
body = MIMEText(msg_content, 'html')
send_email(email, email2, message.as_string(),)
