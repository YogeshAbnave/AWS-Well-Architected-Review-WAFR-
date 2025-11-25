# AWS Well-Architected Review (WAFR) Acceleration with Generative AI (GenAI)

## 🚀 Quick Start - Automatic Deployment

**Push to deploy!** This repository automatically deploys via GitHub Actions.

### Setup Steps

1. **Add GitHub Secrets** (Required)
   - Go to: `Settings → Secrets and variables → Actions → New repository secret`
   - Add: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

2. **Enable Bedrock Models** (Required)
   - Visit: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
   - Enable: Claude 3.5 Sonnet & Titan Text Embeddings V2

3. **Deploy**
   ```bash
   git add .
   git commit -m "Deploy WAFR Accelerator"
   git push origin main
   ```

4. **Monitor Deployment**
   - Go to GitHub → Actions tab
   - Wait ~15-20 minutes

5. **Get Production URL**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name WellArchitectedReviewUsingGenAIStack \
     --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
     --output text \
     --region us-east-1
   ```

6. **Create User & Login**
   ```bash
   # Linux/Mac
   bash deploy.sh post-deploy
   
   # Windows
   .\deploy.ps1 post-deploy
   ```

📖 **Full instructions:** See [PUSH-TO-DEPLOY.md](PUSH-TO-DEPLOY.md) or [PRODUCTION-READY-CHECKLIST.md](PRODUCTION-READY-CHECKLIST.md)

---

## Description

This is a comprehensive SaaS designed to facilitate and expedite the AWS Well-Architected Framework Review process. 

This aims to accelerate AWS Well-Architected Framework Review (WAFR) velocity and adoption by leveraging the power of generative AI to provide organizations with automated comprehensive analysis and recommendations for optimizing their AWS architectures. 

## Core Features

* Ability to upload technical content (for example solution design and architecture documents) to be reviewed in PDF format<br/> 
* Creation of architecture assessment including:
	* Solution summary
	* Assessment
	* Well-Architected best practices
	* Recommendations for improvements
	* Risk
	* Ability to chat with the document as well as generated content
* Creation of Well-Architected workload in Well-Architected tool that has:
	* Initial selection of choices for each of the question based on the assessment.
	* Notes populated with the generated assessment.

## Optional / Configurable Features

* [Amazon Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/) - initial set of Amazon Bedrock Guardrail configurations for Responsible AI. 
	* Default - Enabled
* Amazon OpenSearch Serverless disable redundancy - by default, each Amazon OpenSearch Serverless collection has redundancy and has its own standby replicas in a different Availability Zone. This option allows you to disable redundancy to reduce overall stack cost during development and testing. See Amazon OpenSearch Serverless [How it works](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless-overview.html#serverless-process) for more details.
	* Default - Enabled

_* Note: The above list of features can be individually enabled and disabled by updating the 'optional_features' JSON object in 'app.py' file._

## Technical Architecture

 ![WAFR Accelerator System Architecture Diagram](sys-arch.png)<br/> 

## Prerequisites

Before deploying this solution, ensure you have the following installed and configured:

### Required Software (for manual deployment only)

1. **Docker Desktop** (20.10.0 or later)
   - **Windows:** Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - **macOS:** Download from [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
   - **Linux:** Install Docker Engine via your package manager
   - ⚠️ **Important:** Docker must be running before deployment

2. **Python 3.12+**
   - Download from [python.org](https://www.python.org/downloads/)

3. **Node.js and npm** (for AWS CDK)
   - Download from [nodejs.org](https://nodejs.org/) (LTS version recommended)

4. **AWS CLI**
   - Install from [AWS CLI Installation Guide](https://aws.amazon.com/cli/)
   - Configure with: `aws configure`

5. **AWS CDK**
   - Install globally: `npm install -g aws-cdk`

**Note:** GitHub Actions handles all prerequisites automatically for CI/CD deployment.

### AWS Account Requirements

- AWS Account with appropriate permissions
- Access to Amazon Bedrock models in us-east-1:
  - Claude 3.5 Sonnet
  - Titan Text Embeddings V2
  - Request access at: [Bedrock Model Access](https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess)

### Verify Docker is Running

Before deployment, verify Docker is running:

```bash
# Check Docker version
docker --version

# Check Docker daemon is running
docker info
```

If Docker is not running, start Docker Desktop and wait for it to fully initialize.

## Implementation Guide

### Pre-requisites
* Ensure you have access to the following models in Amazon Bedrock:
	* Titan Text Embeddings V2
	* Claude 3-5 Sonnet
	* Python 3.12+
	* AWS CLI configured

### Preparing and populating Amazon Bedrock Knowledge Base with AWS Well-Architected reference documents

The Amazon Bedrock knowledge base is driven by AWS Well-Architected documents. These documents have been downloaded and placed in the 'well_architected_docs' folder for ease of deployment. They are ingested during the build. 

Please refer to [Refreshing Amazon Bedrock Knowledge Base with latest AWS Well-Architected Reference Documents](refreshing_kb.md) for guidance on how to refresh the documents with future releases of the Well-Architected Framework after the build.
<br/><br/>
Currently, the following AWS Well-Architected lenses are supported:
* AWS Well-Architected Framework Lens
* Data Analytics Lens
* Generative AI Lens
* Financial Services Industry Lens
   
### Manual CDK Deployment (Optional)

If you prefer manual deployment instead of GitHub Actions:

**Linux/Mac:**
```bash
bash deploy.sh pre-req
bash deploy.sh deploy
bash deploy.sh post-deploy
```

**Windows:**
```powershell
.\deploy.ps1 pre-req
.\deploy.ps1 deploy
.\deploy.ps1 post-deploy
```

You can now use the Amazon CloudFront URL from the CDK output to access the application in a web browser.
<br/> 

### Testing the application

Open a new web browser window and copy the Amazon Cloudfront URL copied earlier into the address bar. On the login page, enter the user credentials for the previously created user.<br/>
<br/> 
![Login page](graphics/loginpage.png)<br/> 
<br/> 
On home page, click on the "New WAFR Review" link.
<br/> <br/>
![Welcome page](graphics/home.png)<br/> 
<br/> 
On "Create New WAFR Analysis" page, select the analysis type ("Quick" or "Deep with Well-Architected Tool") and provide analysis name, description, Well Architectd lens, etc. in the input form. <br/>
<br/> 
**Analysis Types**:<br/>
* **"Quick"** - quick analysis without the creation of workload in the AWS Well-Architected tool. Relatively faster as it groups all questions for an individual pillar into a single prompt; suitable for initial assessment. 
* **"Deep with Well-Architected Tool"** - robust and deep analysis that also creates workload in the AWS Well-Architected tool. Takes longer to complete as it doesn't group questions and responses are generated for every question individually. This takes longer to execute. 

![Create new WAFR analysis page](graphics/createnew.png)

* Note: "Created by" field is automatically populated with the logged user name.
  
You have an option to select one or more Well-Architected pillars. <br/><br/>Finally upload the solution architecture / technical design document that needs to be analysed and press the "Create WAFR Analysis" button.<br/> 
<br/> 
Post successful submission, navigate to the "Existing WAFR Reviews" page. The newly submitted analysis would be listed in the table along with any existing reviews. <br/> <br/> 
![Existing WAFR reviews](graphics/existing.png)<br/> 

Once the analysis is marked "Completed", the WAFR analysis for the selected lens would be shown at the bottom part of the page. If there are multiple reviews, then select the relevant analysis from the combo list. 
<br/>

![Create new WAFR analysis page](graphics/output.png)<br/> 

* Note: Analysis duration varies based on the Analysis Type ("Quick" or "Deep with Well-Architected Tool") and number of WAFR Pillars selected. A 'Quick' analysis type with one WAFR pillar is likely to be much quicker than "Deep with Well-Architected Tool" analysis type with all the six WAFR Pillars selected.<br/> 
* Note: Only the questions for the selected Well-Architected lens and pillars are answered. <br/>

To chat with the uploaded document as well as any of the generated content by using the "WAFR Chat" section at the bottom of the "Existing WAFR Reviews" page.
<br/>

![WAFR chat](graphics/chat.png)<br/> 
<br/> 

### Uninstall - CDK Undeploy 

If you no longer need the application or would like to delete the CDK deployment, run the following command:

```
cdk destroy
```

### Disclaimer
You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment.

streamlit run ui_code/WAFR_Accelerator.py --server.port 8501 --server.address localhost
