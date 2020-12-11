const express = require("express");
const Wholesale = require("./models/wholesale_model");
const app = express();
const bodyParser = require("body-parser");

app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.json({ msg: "wholesale_items" });
});

app.get("/api/v1/wholesale", async (req, res) => {
  const wholesale = await Wholesale.find({});
  res.json(wholesale);
});

app.post("/api/v1/wholesale", async (req, res) => {
  const wholesale = new Wholesale({ name: req.body.name });
  const savedWholesaleItem = await wholesale.save();
  res.json(savedWholesaleItem);
});

module.exports = app;
