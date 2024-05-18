# Safe QR | Diploma Work #
***By: Myrzakhanov Abylaykhan CS-2104, Erassyl Omirtay CS-2104, Isagaliyeva Aruzhan CS-2106***

## About Project ##
We have developed a server for analyzing QR codes on potentially malicious objects. Our server analyzes URLs for phishing attempts, phishing within HTML pages, malware, defacement, SQL injection, cross-site scripting (XSS), and utilizes VirusTotal for further analysis.

https://github.com/Futur1stXD/SafeQR/assets/126179639/1e7d1858-562f-407e-97be-6175d55fef14

<img width="554" alt="Снимок экрана 2024-05-18 в 15 13 26" src="https://github.com/Futur1stXD/SafeQR/assets/126179639/7a344911-ab5e-4dea-acf3-5b6cddd0d9b0">

## The stack used ##
To develop the server, we chose the Fast API (Python) as the main tool. In fact, the server receives a URL link and sends it to a certain endpoint, where the analysis takes place, and then the response is returned in JSON format: {"result": "..."}.

A total of 7 endpoints are implemented on the server:

- /phishing - to analyze the presence of phishing,
- /phishing-web - to analyze phishing inside web pages,
- /malware-defacement - to detect malware and defaces,
- /sql-injection - to identify SQL injections,
- /xss - to identify possible attacks through cross-site scripting (XSS),
- /virustotal - for additional analysis using the VirusTotal service,
- /url-info - for getting URLs info.

We used machine learning methods to analyze links. Here is the total amount of data used:
- Phishing (1.100.000 URLs):
  - https://www.kaggle.com/datasets/sid321axn/malicious-urls-dataset
  - https://www.kaggle.com/datasets/taruntiwarihp/phishing-site-urls/data
  - https://github.com/Kiinitix/Malware-Detection-using-Machine-learning/blob/main/Dataset/data.csv
- Phishing-Web (13.000 HTML codes):
  - https://www.kaggle.com/datasets/huntingdata11/
- Malware-Defacement (550.000 URLs):
  - https://www.kaggle.com/datasets/sid321axn/malicious-urls-dataset
- SQL-Injection (31.000 HTML codes):
  - https://www.kaggle.com/datasets/sajid576/sql-injection-dataset
- XSS (13.000 HTML codes):
  - https://www.kaggle.com/datasets/syedsaqlainhussain/cross-site-scripting-xss-dataset-for-deep-learning

For training models we used TensorFlow and sklearn libraries.
The accuracy of the models is:
- Phishing (97%)
- Phishing-Web (88%)
- Malicious-Defacement (99%)
- SQL-Injection (99%)
- XSS (98%)

***All requests to the server are saved in .csv files to further improve the models.***

### How to run the project ###
pip3 install -r ./requirements.txt or pip install -r ./requirements.txt
python3 server.py

For checking the outputs open the **localhost:8080/docs**
