const express = require("express");
const cors = require("cors");
const auteurRoutes = require("./routes/auteur.routes");
const categorieRoutes = require("./routes/categorie.routes");
const livreRoutes = require("./routes/livre.routes");
const authRoutes = require("./routes/auth.routes");
const swaggerUi = require("swagger-ui-express");
const swaggerSpec = require("./swagger");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/auteurs", auteurRoutes);
app.use("/api/categories", categorieRoutes);
app.use("/api/livres", livreRoutes);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

module.exports = app;
