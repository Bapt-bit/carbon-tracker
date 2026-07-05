'use strict';

let indu_checkbox = document.getElementById('indu_process');
let elec_checkbox = document.getElementById('elec_c');
let add_checkbox = document.getElementById('add_step');
let steps = [];

function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}

function get_data_electricity(){

    if (elec_checkbox.checked){
        ajaxRequest('GET','/php/db_requests.php?request=electricity',checkbox_form_elec);
    }
    else {
        document.getElementById('form_elec').innerHTML = '';
    }
}


function get_data_process(){

    if (indu_checkbox.checked){
        ajaxRequest('GET','/php/db_requests.php?request=process',checkbox_form_process);
    }
    else {
        document.getElementById('form_process').innerHTML = '';
    }
}

function checkbox_form_elec(data){
    console.log("electricity");
    console.log(data);
    let code_html = '';
    code_html += '<div class="field-group">';
    code_html += '<label htmlFor="country"+ i.toString() >Choose the electricity origin</label>';
    code_html += ' <select class="big-select" id="country" + i.toString() name="country" multiple size="4">';

    for (const item of data) {
        code_html += '<option value="'+ escapeHtml(item.country) +'">' + escapeHtml(item.country) + '</option>';
    }
    code_html += '</select>';
    code_html += '</div>';
    code_html += '<br>';

    code_html += '<div class="field-group">';
    code_html +=  '<label for="electri">Electricity</label>';
    code_html +=    '<textarea id="electricity" name="message" rows="1" placeholder="Write the electricity consumption in kWh"></textarea>';
    code_html += '</div>';
    code_html += '<br>';
    document.getElementById('form_elec').innerHTML = code_html;

}


function checkbox_form_process(data){

    let code_html = '';
    code_html += '<div class="field-group">';
    code_html += '<label htmlFor="process" + i.toString() >Choose an industrial process</label>';
    code_html += ' <select class="big-select" id="process"+ i.toString() name="process" multiple size="4">';

    for (const item of data) {
        code_html += '<option value="'+ escapeHtml(item.process_name) +'">' + escapeHtml(item.process_name) + '</option>';
    }
    code_html += '</select>';
    code_html += '</div>';
    code_html += '<br>';
    document.getElementById('form_process').innerHTML = code_html;

}


function form(data) {
    /*
    let code_html = '<form method="POST" action = "requete_bdd.php">' + '<label for="material_raw">' + "Choose an option" + '</label>';
    code_html += '<select id="material_raw" name="material[]" multiple>';
    //console.log("DATTTTTTTTTTTa");
    console.log(data[0]);

    for (const item of data) {
        code_html += '<option value="${data[pas]}">'+item.material_name +'</option>';
    }


    code_html += '</form>';
    code_html += '</select>';

    code_html += '<div>';
    code_html += '<label htmlFor="message">Message</label>';
    code_html += '<textarea id="message" rows="5" placeholder="Write the distance made by the product"></textarea>';
    code_html += '</div>';



    code_html += '<button type="button" id="send">Submit</button>'*/

    let code_html = '';
    for (const item of data) {
        code_html += '<option value="'+ escapeHtml(item.material_name) +'">' + escapeHtml(item.material_name) + '</option>';
    }
    code_html += '<option value="'+escapeHtml("processed_material")+'">'+ escapeHtml('processed material')+'</option>';

    document.getElementById('material').innerHTML = code_html;
    //document.getElementById("send").addEventListener("click", getliste);

}


function form_trip(data){
    /*                <div class="field-group">
                    <label for="distance">Distance</label>
                    <textarea id="distance" name="message" rows="1"
                              placeholder="Write the distance made by the product in km"></textarea>
                </div>*/
    let code_html = '';
    let trip_number = 0;
    trip_number = document.getElementById("trip").value;
    for( let i = 0; i < trip_number; i++)
    {

        code_html += '<div class="field-group">';
        code_html += '<label for='+ 'transport'+i.toString()+'>Choose a transport</label>';
        code_html += ' <select class="big-select" id='+'transport'+i.toString()+' name="transport" multiple size="4">';


        for (const item of data) {
            code_html += '<option value="'+ escapeHtml(item.vehicle_type) +'">' + escapeHtml(item.vehicle_type) + '</option>';
        }
        code_html += '</select>';
        code_html += '</div>';
        code_html += '<br>';

        code_html += '<div class="field-group">';
        code_html += '<label for="distance'+i.toString()+'">Distance</label>';
        code_html += '<textarea id="distance'+i.toString()+'" name="message" rows="1" placeholder="Write the distance for this trip in km"></textarea>';
        code_html += '</div>';
        code_html += '<br>';

    }
    document.getElementById('form_trip').innerHTML = code_html;
    //document.getElementById("send").addEventListener("click", getliste);


}

let materials = [];
function getliste() {let select = document.getElementById("material").value;;console.log(select);
}
function getdatabase_data(){
    ajaxRequest('GET','/php/db_requests.php?request=raw_material',form);
}



function get_trip_form(){
    setTimeout(() => {
        ajaxRequest('GET','/php/db_requests.php?request=trip',form_trip);
    }, "1000");

}


function sendStepsToServer(steps) {
    const processed = processStepsForServer(steps);
    const body = 'data=' + encodeURIComponent(JSON.stringify(processed));
    ajaxRequest('POST', '/php/db_requests.php?request=save_steps', function(response) {
        console.log('Réponse serveur:', response);
        const link = document.createElement('a');
        link.href = '/' + response.report;
        link.textContent = '📄 Download your report';
        link.target = '_blank';
        link.className = 'report-link';
        document.getElementById('footprintForm').appendChild(link);
    }, body);

}

function processStepsForServer(steps) {
    return steps.map(step => {
        const payload = {};

        for (const key in step) {
            const value = step[key];
            if (!Array.isArray(value)) continue; // on garde uniquement les choix (selects multiples)

            payload[key] = value;

            if (key === 'material' && step.quantity) {
                payload.quantity = step.quantity;
            } else if (key.startsWith('transport')) {
                const index = key.replace('transport', '');
                if (step['distance' + index]) {
                    payload['distance' + index] = step['distance' + index];
                }
            } else if (key === 'country' && step.electricity) {
                payload.electricity = step.electricity;
            }
        }

        return payload;
    });
}

function isValidNumber(value) {
    return value !== undefined && value !== '' && !isNaN(value) && Number(value) > 0;
}

function isStepValid(formData) {
    const hasMaterial = Array.isArray(formData.material) && formData.material.length > 0;

    let hasTransportWithDistance = false;
    for (const key in formData) {
        if (key.startsWith('transport')) {
            const idx = key.replace('transport', '');
            if (Array.isArray(formData[key]) && formData[key].length > 0 && isValidNumber(formData['distance' + idx])) {
                hasTransportWithDistance = true;
                break;
            }
        }
    }

    const hasElectricity = Array.isArray(formData.country) && formData.country.length > 0 && isValidNumber(formData.electricity);
    const hasProcessAndMaterial = Array.isArray(formData.process) && formData.process.length > 0 && hasMaterial;

    return hasTransportWithDistance || hasElectricity || hasMaterial || hasProcessAndMaterial;
}




getdatabase_data();
document.getElementById("trip").addEventListener("keypress",get_trip_form);
document.getElementById('elec_c').addEventListener('change',get_data_electricity);
document.getElementById('indu_process').addEventListener('change',get_data_process);
//document.getElementById('button').addEventListener('click',add_steps);
document.getElementById('footprintForm').addEventListener('submit', function(e) {
    e.preventDefault();

    const formData = {};
    for (const el of e.target.elements) {
        if (!el.id) continue;
        formData[el.id] = (el.tagName === 'SELECT' && el.multiple)
            ? Array.from(el.selectedOptions).map(o => o.value)
            : el.value;
    }

    if (!isStepValid(formData)) {
        alert('Veuillez renseigner au moins : un matériau, un matériau + procédé, un transport avec sa distance, ou une électricité.');
        return;
    }

    steps.push(formData);

    if (add_checkbox.checked) {
        console.log('Step stored:', steps);
        e.target.reset();
    } else {

        sendStepsToServer(steps);
        steps = [];
    }
        //console.log('All steps:', steps);
        // ici tu peux envoyer `steps` au serveur (ex: ajaxRequest('POST', ..., steps))

});


