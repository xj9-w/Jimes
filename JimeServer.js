const fs = require('fs-extra');
const fastify = require("fastify")({logger: false,});
require('dotenv').config();

const DataPath = "./time.txt"

const Round = Math.round

function GetData() {
  return fs.readFileSync(DataPath, "utf8")
}

fastify.post("/", function (request, reply) {
  const Add = request.body["Add"]
  
  if (Add == undefined || request.body["Key"] !== process.env.Key) {
    return "invalid request";
  }
  
  const NewData = parseFloat(GetData()) + Add
  fs.writeFileSync(DataPath, NewData.toString()) 
  
  return Round(NewData)
});

fastify.get("/", function(request, reply) {
  return Round(GetData())
});

fastify.listen(
  { port: process.env.PORT, host: "0.0.0.0" },
  function (err, address) {
    if (err) {
      console.error(err);
      process.exit(1);
    }
    console.log(`Your app is listening on ${address}`);
  }
);
