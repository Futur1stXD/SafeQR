import pickle
import cv2
import requests
import ipaddress
import socket
import numpy as np
import tensorflow as tf 
import csv
import os

from nltk.tokenize import RegexpTokenizer
from nltk.stem.snowball import SnowballStemmer
from dotenv import load_dotenv


# Helping functions
def convert_to_ascii(sentence):
    try: 
        sentence_ascii = []

        for i in sentence:
            if ord(i) < 8222:
                sentence_ascii.append(134)
            if ord(i) == 8221: 
                sentence_ascii.append(129)
            if ord(i) == 8220: 
                sentence_ascii.append(130)
            if ord(i) == 8216:
                sentence_ascii.append(131)
            if ord(i) == 8217: 
                sentence_ascii.append(132)
            if ord(i) == 8211: 
                sentence_ascii.append(133)

            if ord(i) <= 128:
                sentence_ascii.append(ord(i))

        if len(sentence_ascii) > 10000:
            sentence_ascii = sentence_ascii[:10000]
        else:
            sentence_ascii += [0] * (10000 - len(sentence_ascii))
        
        zer = np.array(sentence_ascii).reshape((100, 100))
        return zer
    except Exception as e:
        print("Error while converting to ASCII: ", e)
        return "error"


def get_html_from_url(url: str) -> str:
    try:
        response = requests.get(url)
        response.raise_for_status()

        return response.text
    except Exception as e:
        print("Error while getting HTML", e)
        return "error"


# Phishing / Malware / Defacement
async def phishing_malware_defacement(url: str, model_filename: str, attack_type: str) -> dict:
    try:
        tokenizer = RegexpTokenizer(r'[A-Za-z]+')
        stemmer = SnowballStemmer('english')

        tokenized = tokenizer.tokenize(url)
        stemmed = [stemmer.stem(word) for word in tokenized]
        sent = ' '.join(stemmed)

        loaded_model = pickle.load(open(f'./models/{model_filename}', 'rb'))

        prediction = loaded_model.predict([sent])

        result = prediction[0]

        csv_path = './collecting/overall.csv'
        file_exists = os.path.isfile(csv_path)

        with open('./collecting/overall.csv', mode='a', newline='') as file:
            writer = csv.writer(file)
            if not file_exists:
                writer.writerow(['url', 'label', 'attack_type'])
            writer.writerow([url, result, attack_type])
            
        return {"result": result}
    except Exception as e:
        print(f"Error while analyzing {attack_type}: {e}")
        return {"result": "error"}


# Phishing Web / SQL Injection / XSS
async def phishingWeb_sql_xss(url: str, model_filename: str, attack_type: str) -> dict:
    try:
        html = get_html_from_url(url)
        
        if html == 'error':
            return {"result": "error"}
        
        model = tf.keras.models.Sequential([
            tf.keras.layers.Conv2D(64, (3, 3), activation=tf.nn.relu, input_shape=(100, 100, 1)),
            tf.keras.layers.MaxPooling2D(2, 2),
            tf.keras.layers.Conv2D(128, (3, 3), activation='relu'),
            tf.keras.layers.MaxPooling2D(2, 2),
            tf.keras.layers.Conv2D(256, (3, 3), activation='relu'),
            tf.keras.layers.MaxPooling2D(2, 2),
            tf.keras.layers.Flatten(),
            tf.keras.layers.Dense(256, activation='relu'),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dense(1, activation='sigmoid')
        ])

        model.load_weights(f'./models/{model_filename}')

        preprocessed_html = convert_to_ascii(html)
        
        if not isinstance(preprocessed_html, np.ndarray):
            return {attack_type: preprocessed_html}

        x = np.asarray(preprocessed_html, dtype='float')
        x = cv2.resize(x, dsize=(100, 100), interpolation=cv2.INTER_CUBIC)
        x /= 128
        x = np.expand_dims(x, axis=0)
        x = np.expand_dims(x, axis=-1)
        
        prediction = model.predict(x)
        
        result = 'good' if prediction[0][0] < 0.5 else 'bad'

        csv_path = './collecting/overall_url_results.csv'
        file_exists = os.path.isfile(csv_path)

        with open(csv_path, mode='a', newline='') as file:
            writer = csv.writer(file)
            if not file_exists:
                writer.writerow(['url', 'label', 'attack_type'])
            writer.writerow([url, result, attack_type])

        return {"result": result}
    except Exception as e:
        print("Error in phishingWeb_sql_xss: ", e)
        return {"result": "error"}


# VirusTotal API
async def virusTotal_API(url: str) -> dict:
    try:
        load_dotenv()
        API_KEY = os.getenv("API_KEY")
        
        params = {'apikey': API_KEY, 'resource': url}
        report_result = requests.get('https://www.virustotal.com/vtapi/v2/url/report', params=params).json()

        result = "good" if report_result["positives"] == 0 else "bad"

        csv_path = './collecting/virusTotal_results.csv'
        file_exists = os.path.isfile(csv_path)

        with open(csv_path, mode='a', newline='') as file:
            writer = csv.writer(file)

            if not file_exists:
                writer.writerow(['url', 'label'])
            writer.writerow([url, result])

        return {"result": result}
    except Exception as e:
        print("Error in VirusTotal: ", e)
        return {"result": "error"}


# URL INFO
async def url_info(url: str) -> dict:
    try:
        domain = getDomain(url = url)
        
        ip_address = getIp(domain = domain)

        countryCode, city = await getRegion(ip_address)
        
        result = {"domain": domain, "ip_address": ip_address, "countryCode": countryCode, "city": city}

        csv_path = './collecting/overall_url_info.csv'
        file_exists = os.path.isfile(csv_path)

        with open(csv_path, mode='a', newline='') as file:
            writer = csv.writer(file)

            if not file_exists:
                writer.writerow(['url', 'domain', 'ip_address', 'country_code', 'city'])
            writer.writerow([url, domain, ip_address, countryCode, city])

        return result
    except Exception as e:
        print(f"Error in url_info: {e}")


# Get Domain of URL
def getDomain(url: str) -> str:
    if check_protocol(url):
        url = url[8:]
    else:
        url = url[7:]
    
    return url.split('/')[0]


# Get IP-Address of Domain
def getIp(domain: str) -> str:
    try:
        ipaddress.ip_address(domain)
        return domain
    
    except:
        return socket.gethostbyname(domain)


# Get Country Code & City
async def getRegion(ip: str) -> tuple:
    params = ['status', 'countryCode', 'city']

    request = requests.get('http://ip-api.com/json/' + ip, params={'fields': ','.join(params)})

    info = request.json()
    
    if info.get('status') == 'success':
        return info.get('countryCode'), info.get('city')
    else:
        return "none", "none"


# Function for checking HTTPS protocol
def check_protocol(url: str) -> bool:
    if url.startswith('https'):
        return True
    
    return False