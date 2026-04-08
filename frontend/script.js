async function getCounter() {
    try {
        const response = await fetch('https://cflxeq0e98.execute-api.us-east-1.amazonaws.com/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                "operation": "update",
                "payload": { "Key": { "MetricName": "homepage_hits" } }
            })
        });

        const data = await response.json(); 
        
        const count = data.count;

        document.getElementById('visitor-counter').innerText = count;

    } catch (error) {
        console.error('Error:', error);
        document.getElementById('visitor-counter').innerText = "Fehler";
    }
}

getCounter();