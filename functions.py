import pickle
import cv2
import requests
import numpy as np
import tensorflow as tf 

from nltk.tokenize import RegexpTokenizer
from nltk.stem.snowball import SnowballStemmer


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

        return {attack_type: prediction[0]}
    except Exception as e:
        print(f"Error while analyzing {attack_type}: {e}")
        return {attack_type: "error"}


# Phishing Web / SQL Injection / XSS
async def phishingWeb_sql_xss(url: str, model_filename: str, attack_type: str) -> dict:
    try:
        html = get_html_from_url(url)
        
        if html == 'error':
            return {attack_type: "error"}
        
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
        
        if prediction[0][0] < 0.5:
            return {attack_type: 'good'}
        else:
            return {attack_type: 'bad'}
    
    except Exception as e:
        print(e)
        return {attack_type: "error"}