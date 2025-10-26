package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Testazurerbacmanagement(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name": "test-rg",
			"location":           "West Europe",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndPlan(t, terraformOptions)

	// Validate the plan
	planOutput := terraform.Plan(t, terraformOptions)
	assert.Contains(t, planOutput, "Plan:")
}

func TestValidateInputs(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name": "",
			"location":           "West Europe",
		},
	}

	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err)
}
