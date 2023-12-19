
const API_URL = "<API_URL>"
const recordID = ""

//Send the record ID from the URL to serverless back end
function sendURLParams() {
    // get airtable record ID from URL
    const queryString = window.location.search;
    const urlParams = new URLSearchParams(queryString);
    recordID = urlParams.get("id");
    var raw = JSON.stringify({ "id" : recordID });
    
    // instantiate a headers object
    var myHeaders = new Headers();
    // add content type header to object
    myHeaders.append("Content-Type", "application/json");
    // create a JSON object with parameters for API call and store in a variable
    var requestOptions = {
        method: 'GET',
        headers: myHeaders,
        body: raw,
        redirect: 'follow'
    };

    // make API call with parameters and use promises to get response
    fetch(API_URL+"/file/", requestOptions)
    .then(response => response.text())
    .then(result => fillData(JSON.parse(JSON.parse(result))))
    .catch(error => console.log('error', error));
}

function fillData(result){
    console.log(result);
    var fileName = result.file_name;
    var deadlineArray = result["deadline"].split("-");
    var link = result["link"];
    
    var dlYear = deadlineArray[0];
    var dlMonth = deadlineArray[1];
    var dlDay = deadlineArray[2];

    var deadline = dlMonth + "/" + dlDay + "/" + dlYear;

    document.getElementById("file_name").innerText = fileName;
    document.getElementById("deadline_head").innerText = deadline;
    document.getElementById("deadline_foot").innerText = deadline;
    document.getElementById("file_link").href = link;
}

//Send form data to back end on submit

(() => {
    const form = document.getElementById("radio-form");
    const apiEndpoint = API_URL+"/file-feedback/";
    const subBtn = document.getElementById("submit-btn");

    form.onsubmit = event => {
        event.preventDefault();
        subBtn.style.background = "#f37820"
        subBtn.value = ("Sending...");

        try {
            var selection = document.querySelector('input[name="response"]:checked').value;
        } catch (TypeError) {
            subBtn.value = "Submit";
            alert("Must update file status before submitting");
            return;
        }
        
        var raw = JSON.stringify({ "id" : recordID , "form_response" : selection });

        var myHeaders = new Headers();
        
        myHeaders.append("Content-Type", "application/json");
       
        var requestOptions = {
            method: 'POST',
            headers: myHeaders,
            body: raw,
            redirect: 'follow'
        };

        fetch(apiEndpoint, requestOptions)
        .then(response => response.text())
        .then(result => processSubmitResult(JSON.parse(result), subBtn))
        .catch(error => console.log('error', error));
    };
})();

function processSubmitResult(result, subBtn){
    console.log("API Response: "+result);
    if (result == "Success" ) {
        subBtn.value = "Submitted!";
        subBtn.style.background = "rgb(129, 216, 111)";
    }
    else {
        subBtn.value = "Failed";
    }
}

window.onload = sendURLParams();
