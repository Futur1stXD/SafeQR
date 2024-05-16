import uvicorn
import asyncio

import functions

from fastapi import FastAPI


app = FastAPI()


@app.post('/phishing')
async def phishing_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.phishing_malware_defacement(url, 'phishing.pkl', 'phishing')

        return request
    except Exception as e:
        print("Error while making POST in phishing: ", e)
        return request


@app.post('/phishing-web')
async def phishingWeb_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.phishingWeb_sql_xss(url, 'phishing-web.h5', 'phishingWeb')

        return request
    except Exception as e:
        print("Error while making POST in phishingWeb: ", e)
        return request


@app.post('/malware-defacement')
async def malware_defacement_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.phishing_malware_defacement(url, 'malware-defacement.pkl', 'malware_defacement')

        return request
    except Exception as e:
        print("Error while making POST in malware_defacement: ", e)


@app.post('/sql-injection')
async def malware_defacement_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.phishingWeb_sql_xss(url, 'sql-injection.h5', 'sql_injection')

        return request
    except Exception as e:
        print("Error while making POST in sql_injection: ", e)


@app.post('/xss')
async def xss_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.phishingWeb_sql_xss(url, 'xss.h5', 'xss')

        return request
    except Exception as e:
        print("Error while making POST in xss: ", e)


@app.post('/virus-total')
async def virusTotal_analyze(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.virusTotal_API(url)

        return request
    except Exception as e:
        print("Error while making POST in Virus Totel: ", e)


@app.post('/url-info')
async def url_info(url_data: dict) -> dict:
    try:
        url = url_data.get('url')

        request = await functions.url_info(url)

        return request
    except Exception as e:
        print("Error while making POST in url-info: ", e)
        return {"url_info": "error"}


# Server Settings & Main
async def main():
    config = uvicorn.Config("server:app", host='0.0.0.0', port=8080, log_level='info')
    server = uvicorn.Server(config = config)
    await server.serve()

if __name__ == '__main__':
    asyncio.run(main())