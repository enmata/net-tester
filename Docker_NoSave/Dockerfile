FROM public.ecr.aws/lambda/python:3.8
# Custom Docker image for network testing NUMBER 3

# Copying function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Setting initial CMD
CMD [ "app.handler" ]
