# TERRAFORM CI/CD PIPELINE - FINAL EXERCISE

This project contains a simple spring boot REST API that will display the message "Hello World!".  The project has a CI/CD pipeline attached to it that builds the spring boot jar, runs unit tests, then deploys the spring boot jar to AWS.  Once this pipeline has run successfully, you will be able to enter the following in any browser to display the message "Hello World!"    

```
http://<host-name>:8080/hello-world
```


## CI/CD PIPELINE DETAILS

The CI/CD pipeline attached to this project consists of 6 stages, which run in the following order:
* mvn-test
* mvn-build
* terraform-validate
* terraform-plan
* terraform-apply
* terraform-destroy

Each of these stages is discussed in more detail below.

### mvn-test
This stage is responsible for running junit tests and consists of two jobs:

**test1**
> This test only executes our HelloWorldControllerTest via maven command. We broke this out from the build step just to demonstrate having a test stage and also so we can force it to fail to demonstrate that the pipeline will stop on failure.  This step is not allowed to fail. If junit fails, we don't want to try and build the deployable. The target folder is persisted as an artifact. This folder contians test report.  Normally this would run as part of the mvn clean install in the build job, but we split it out here just so we can demonstrate that the pipeline will stop of the junits fail (and not proceed to the build stage).

**test2**
> This test just spits out literal string to the console output.  This job was added to demonstrate parallel execution of jobs in a given stage.

### mvn-build
This stage consists of one job:

**build**
> This job builds the spring boot jar using mvn clean install that we will be deploying to AWS.  We chose not to run the tests here, since they were run in the preceding test stage and this job won't be reached if they fail.

### terraform-validate

This stage consists of one job:

**validate**
> This job validates the terraform syntax and inner references specified in the tf configuration file(s). If you are developing in an IDE with a terraform plug-in, it will show you any errors in the IDE.  This step will just automate that process and fail the pipeline if the terraform configuration is invalid.

### terraform-plan

This stage consists of one job:

**plan**
> Terraform will compare your tf configuration with the tf state and show you all the resources that need to be created, changed or destroyed.  Here we are specifying an 'out' option to save the generated plan as an artifact so it can be used in the terraform apply step.  If you run terraform plan without the optional 'out' then it will create a speculative plan, which is a description of the effect of the plan but without any intent to actually apply it.


### terraform-apply

This stage consists of one job:

**apply**
> Deploy the infrastructure using terraform apply, using the tf plan from the previous stage.  This will be a manual step, so we can verify the plan prior to applying the plan to the actual infrastructure.  The auto-approve parameter is necessary so a human doesn't have to type 'yes' to approve the plan.  We save the tf state here as an artifact so it will be browsable from the gitlab UI and available for the destroy stage.
### terraform-destroy

This stage consists of one job:

**destroy**
> Destroys the infrastructure created by our tf configuration.  This is a manual step for obvious reasons.  The auto-approve parameter is necessary so a human doesn't have to type 'yes' to approve the destroy.

## RESOURCES

The following resources were helpful along the way:

```
HOW TO INTEGRATE TERRAFORM WITH GITLAB CI/CD
https://medium.com/@nbqadri/beginners-guide-to-using-terraform-via-gitlab-ci-cd-pipelines-for-aws-a600ca4588c4
https://dev.to/fabiomatavelli/setup-gitlab-ci-with-terraform-26l1

HOW TO DELETE EC2 INSTANCE PROFILE FROM COMMAND LINE
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_manage_delete.html
https://docs.aws.amazon.com/IAM/latest/APIReference/API_DeleteInstanceProfile.html
https://docs.aws.amazon.com/cli/latest/reference/iam/delete-instance-profile.html
```
