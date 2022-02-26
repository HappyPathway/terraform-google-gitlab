package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestGoogleGitlabMain(t *testing.T) {
	t.Parallel()
	testExampleDir := "examples/google_gitlab_main"
	stage := test_structure.RunTestStage
	copyToDisk := test_structure.CopyTerraformFolderToTemp
	exampleDir := copyToDisk(t, "../", testExampleDir)
	defer stage(t, "teardown_GoogleGitlabMain_module", func() { teardownGoogleGitlabMain(t, exampleDir) })
	stage(t, "plan_GoogleGitlabMain_module", func() { planGoogleGitlabMain(t, exampleDir) })
	stage(t, "deploy_GoogleGitlabMain_module", func() { deployGoogleGitlabMain(t, exampleDir) })
	stage(t, "validate_GoogleGitlabMain_module", func() { validateGoogleGitlabMain(t, exampleDir) })
}

func planGoogleGitlabMain(t *testing.T, exampleDir string) {
	opts := createGoogleGitlabMainOpts(t, exampleDir)
	test_structure.SaveTerraformOptions(t, exampleDir, opts)
	terraform.InitAndPlan(t, opts)
}

func deployGoogleGitlabMain(t *testing.T, exampleDir string) {
	opts := createGoogleGitlabMainOpts(t, exampleDir)
	test_structure.SaveTerraformOptions(t, exampleDir, opts)
	terraform.InitAndApply(t, opts)
}

func teardownGoogleGitlabMain(t *testing.T, exampleDir string) {
	opts := test_structure.LoadTerraformOptions(t, exampleDir)
	defer terraform.Destroy(t, opts)
}

func validateGoogleGitlabMain(t *testing.T, exampleDir string) {
	opts := test_structure.LoadTerraformOptions(t, exampleDir)
	validateGoogleGitlabMainModule(t, opts)

}

func createGoogleGitlabMainOpts(t *testing.T, terraformDir string) *terraform.Options {
	/*
		helper variables. Most modules will use these values. And a uniqueID is created for proper naming
		of your resources. As these tests may need to be run concurrently, it is important that resources
		be named using randomization.
	*/

	/*
		When testing, you will want to pass in known values as the inputs and compare against the outputs.
		Here, we are specifying these known inputs. We will compare them to the outputs in following
		validateGoogleGitlabMainModule function.
	*/

	// WE NEED TO MAKE SURE THAT RESOURCES HAVE UNIQUE NAMES
	uniqueID := strings.ToLower(random.UniqueId())

	return &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"random":         uniqueID,
			"smtp_password":  "G00b3rs!!",
			"smtp_user_name": "dave-cft",
		},
	}
}

func validateGoogleGitlabMainModule(t *testing.T, opts *terraform.Options) {
	/*
		The following code illustrates how to make assertions in your testing code.
		This example is from the singleinstance module, that module returns an output
		called instance_url. Here we are getting this output and comparing its value against
		a string. By providing inputs in the createGoogleGitlabMainOpts function
		above, and then comparing against known outputs, you can easily and effectively test your
		Terraform code.

		instanceURL := terraform.Output(t, opts, "instance_url")
		fmtInstanceURL := fmt.Sprintf("%s", instanceURL)
		assert.Contains(t, fmtInstanceURL, "google")

		For useful information on what can be output from Terraform into Terratest and the various functions to call
		to get specific data types, check this link:
		https://github.com/gruntwork-io/terratest/blob/master/modules/terraform/output.go

		For useful information on the various types of assertions that can be made, check this link:
		https://godoc.org/github.com/stretchr/testify/assert
	*/

	// This is a place holder. Some Code Editors are smart and remove unused imports.
	// Since I dont want you to have to hunt down this import, I'm leaving this function call in place.
	// THIS WILL NEED TO BE MODIFIED.
	// assert.Contains(t, fmtInstanceURL, "google")
}
