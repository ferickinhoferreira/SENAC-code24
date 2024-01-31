import express from 'express';
import bodyParser from 'body-parser';

const app = express();
app.use(bodyParser.json());

const clientes = [
    { id: 1, nome: "João Batista"},
    { id: 2, nome: "Erick"}
];

// Rota principal
app.get("/", (req, res) => {
    res.status(200).send("Welcome to our app");
});

// Consultar todos os clientes
app.get("/clientes", (req, res) => {
    res.status(200).json(clientes);
});

// Adicionar novo cliente
app.post("/clientes", (req, res) => {
    const novoCliente = req.body;
    clientes.push(novoCliente);
    res.status(201).send("Cliente adicionado com sucesso");
});

export default app;