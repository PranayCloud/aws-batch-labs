Act as a Devloper,

create a project named as ai image visualizer, where we would upload an image to s3 bucket, then rekognition will extract the text from it & then we send the text to comprehend, which helps us to finalize the sentiment.

task: to create a web application to be hosted on aws ec2 instance, which allows you to upload the image to teh image, which goes to s3 & on the same page you see the extracted text & its sentimanet, this should look like a very user frriendly application.

# AI Image Visualizer Project Requirements

## Overview
The AI Image Visualizer project is a web application that allows users to upload images, extract text from those images using AWS Rekognition, and analyze the sentiment of the extracted text using AWS Comprehend. The application will be hosted on an AWS EC2 instance and will provide a user-friendly interface for seamless interaction.

## Functional Requirements
1. **Image Upload**: Users should be able to upload images in common formats (JPEG, PNG) through the web interface.
2. **S3 Integration**: Uploaded images should be stored in an AWS S3 bucket for processing.
3. **Text Extraction**: Use AWS Rekognition to extract text from the uploaded images.
4. **Sentiment Analysis**: Send the extracted text to AWS Comprehend to determine the sentiment (positive, negative, neutral).
5. **Display Results**: Display the extracted text and its sentiment on the same page after processing.

##Infrastrucvture requirement

create a cloudformation stack to 

create a VPC, internet gateway, public subnet, security group, ec2 instance, iam for all, ec2 to send to s3 bucket, then rekignition, comprehend and all , so we havce infra stcak.

we will build the code & push it to s3, the ec2 instance gets the app code via userdata script & runs the application, then we access the app using poublic ip.

we should have one shell script which works as a pipeline to execute the things in the flow.