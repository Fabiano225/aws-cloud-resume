async function getCounter() {
    try {
        const response = await fetch('https://ubani4qtj1.execute-api.us-east-1.amazonaws.com/production/DynamoDBManager', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                "operation": "update",
                "payload": {
                    "Key": { "MetricName": "homepage_hits" }
                }
            })
        });

        const data = await response.json();
        const parsedBody = JSON.parse(data.body);             
        const count = parsedBody.Attributes.VisitorCount;

        document.getElementById('visitor-counter').innerText = count;

    } catch (error) {
        console.error('Error:', error);
        document.getElementById('visitor-counter').innerText = "Fehler";
    }
}

getCounter();