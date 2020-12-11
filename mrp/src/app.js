const express = require("express");
const MRP = require("./models/mrp_model");
const app = express();
const bodyParser = require("body-parser");

app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.json({ msg: "MRP items" });
});

app.get("/api/v1/mrp", async (req, res) => {
  const mrp = await MRP.find({});
  res.json(mrp);
});

app.post("/api/v1/mrp", async (req, res) => {
  const mrp = new MRP({ name: req.body.name });
  const savedMRPitem = await mrp.save();
  res.json(savedMRPitem);
});

module.exports = app;
