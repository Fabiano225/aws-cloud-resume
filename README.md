# AWS Cloud Resume Challenge

This repository contains the code and infrastructure definitions for my Cloud Resume Challenge. This project is a full-stack serverless application designed to showcase my skills in AWS, Infrastructure as Code, and DevOps best practices.

## 🚀 Live Demo
*[fabiano-petillo.dev](https://fabiano-petillo.dev/)*
---

## 🛠 Project Progress Tracker

- [x] **Phase 1: Frontend**
    - [x] Create a professional resume in HTML.
    - [x] Style the resume with CSS.
- [x] **Phase 2: S3 & CloudFront Hosting**
    - [x] Deploy static files to an S3 Bucket.
    - [x] Configure CloudFront for HTTPS and global delivery.
- [x] **Phase 3: Backend (The Visitor Counter)**
    - [x] Create a DynamoDB table to store visitor counts.
    - [x] Write a Python Lambda function to update/retrieve the count.
    - [x] Set up API Gateway (REST API) to trigger the Lambda.
- [x] **Phase 4: Infrastructure as Code (IaC)**
    - [x] Define all resources using Terraform.
- [ ] **Phase 5: CI/CD Pipeline**
    - [ ] Set up GitHub Actions to auto-deploy frontend and backend changes.

---

## 🏗 Current Architecture

Right now, the project is a static website consisting of:
* **HTML5**
* **CSS3**
* **Javascript**
* **DynamoDB**
* **Python**

---

## 🧠 Lessons Learned (So Far)
* **Frontend:** I focused on keeping the frontend lightweight. Since my goal is Cloud Engineering rather than Frontend Development, I prioritized clean code over complex frameworks like React.

* **S3:** Quick and painless deployment of static content using S3’s native hosting capabilities.
  
* **DNS/HTTPS:** Successfully navigated the integration between Name.com and AWS. This involved configuring DNS records and mastering the validation process for SSL certificates to ensure the site was secure and professional.
  
* **DynamoDB:** Truly "Plug & Play." Setting up the NoSQL schema for a simple visitor counter was the most straightforward part of the backend.
  
* **API Gateway:** This was the most challenging component.
  * **Stage Management:** Understanding the lifecycle of deployments, stages, and how Invoke URLs change.
  * **CORS:** A classic pitfall—learned the hard way that explicit CORS configuration is mandatory for cross-origin frontend requests.
  * **Integration:** Spent significant time debugging the handshake between the Gateway and Lambda.
* **Lambda & Python:** 
  * **Data Types:** Encountered issues with JSON parsing where numeric values from the event body required explicit type casting to int for DynamoDB compatibility.
  * **Boto3:** Refined the logic for handling API Gateway proxy integrations, ensuring the response dictionary (status codes, headers, body) strictly follows the required schema.
---

## 📬 Contact
* **LinkedIn:** [Fabiano Petillo](https://linkedin.com/in/fabiano-petillo)
