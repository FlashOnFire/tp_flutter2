require("dotenv").config();
const app = require("./app");

app.listen(process.env.PORT, () => {
  console.log(`API lancée sur http://localhost:${process.env.PORT}`);
});
