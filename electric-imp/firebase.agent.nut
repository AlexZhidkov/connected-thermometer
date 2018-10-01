#require "Firebase.agent.lib.nut:3.1.2"

const FIREBASE_NAME = "YOUR_FIREBASE_NAME";
const FIREBASE_AUTH_KEY = "YOUR_FIREBASE_AUTH_KEY";

firebase <- Firebase(FIREBASE_NAME, FIREBASE_AUTH_KEY);

device.on("event", function(event) {
    agentId = split(http.agenturl(), "/").pop();
    event.time <- formatDate();
    firebase.write("/data/"+agentId, event, function(error, data) {
        if (error) {
        server.error(error);
        } else {
        server.log(data);
        }
    });
});

// Formats the date object as a UTC string
function formatDate() {
    local d = date();
    return format("%04d-%02d-%02d %02d:%02d:%02d", d.year, (d.month+1), d.day, d.hour, d.min, d.sec);
}