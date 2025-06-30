package controller

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/selection"
	labelutil "k8s.io/kubernetes/pkg/util/labels"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/predicate"
)

func GetDXPMetadataConfigMapSelector() labels.Selector {
	isDXPMetadataType, _ := labels.NewRequirement(
		MetadataTypeLabelKey,
		selection.Equals,
		[]string{MetadataTypeLabelValueDXP},
	)
	isSource, _ := labels.NewRequirement(
		IsSyncedCopyLabelKey,
		selection.DoesNotExist,
		[]string{},
	)

	return labels.NewSelector().Add(
		*isDXPMetadataType,
		*isSource,
	)
}

func (r *DXPMetadataConfigMapController) Reconcile(
	ctx context.Context,
	req ctrl.Request,
) (ctrl.Result, error) {
	log := logf.FromContext(ctx)

	cm := &corev1.ConfigMap{}

	if err := r.Get(ctx, req.NamespacedName, cm); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	dxpNamespace := cm.GetNamespace()
	virtualInstanceId := cm.GetLabels()[VirtualInstanceIdLabelKey]

	extensionNamespaceList := &corev1.NamespaceList{}

	dxpNamespaceLabelRequirement, err := labels.NewRequirement(
		DXPNamespaceLabelKey,
		selection.Equals,
		[]string{dxpNamespace},
	)
	managedByLiferayLabelRequirement, err := labels.NewRequirement(
		ManagedByLabelKey,
		selection.Equals,
		[]string{ManagedByLabelValueLiferayOperator},
	)
	virtualInstanceIdLabelRequirement, err := labels.NewRequirement(
		VirtualInstanceIdLabelKey,
		selection.Equals,
		[]string{virtualInstanceId},
	)

	if err != nil {
		log.Error(
			err,
			"Failed to create label requirements to query extension Namespaces by dxpNamespace and virtualInstanceId",
			"dxpNamespace",
			dxpNamespace,
			"virtualInstanceId",
			virtualInstanceId,
		)

		return ctrl.Result{}, err
	}

	listOpts := []client.ListOption{
		client.InNamespace(dxpNamespace),
		client.MatchingLabelsSelector{
			Selector: GetDXPMetadataConfigMapSelector().Add(
				*dxpNamespaceLabelRequirement,
				*managedByLiferayLabelRequirement,
				*virtualInstanceIdLabelRequirement,
			),
		},
	}

	if err := r.List(ctx, extensionNamespaceList, listOpts...); err != nil {
		log.Error(
			err,
			"Failed to list DXP metadata ConfigMaps for virtualInstanceId",
			"dxpNamespace",
			dxpNamespace,
			"virtualInstanceId",
			virtualInstanceId,
		)

		return ctrl.Result{}, err
	}

	dxpMetadataConfigMap := corev1.ConfigMap{}

	if err := r.Get(ctx, req.NamespacedName, cm); err != nil {
		return ctrl.Result{}, err
	}

	for _, ns := range extensionNamespaceList.Items {
		dxpMetadataConfigMapCopyToSync := dxpMetadataConfigMap.DeepCopy()
		dxpMetadataConfigMapCopyToSync.ObjectMeta = metav1.ObjectMeta{
			Name: dxpMetadataConfigMap.Name,
			Namespace: ns.Name,
			Labels: labelutil.CloneAndAddLabel(
				dxpMetadataConfigMap.Labels,
				IsSyncedCopyLabelKey,
				"true",
			),
		}

		_ = r.Create(ctx, dxpMetadataConfigMapCopyToSync)
	}

	return ctrl.Result{}, nil
}

func (r *DXPMetadataConfigMapController) SetupWithManager(mgr ctrl.Manager) error {
	selector := GetDXPMetadataConfigMapSelector()
	labelSelector, err := metav1.ParseToLabelSelector(selector.String())
	predicate, err := predicate.LabelSelectorPredicate(*labelSelector)

	if err != nil {
		return err
	}

	return ctrl.NewControllerManagedBy(
		mgr,
	).For(
		&corev1.ConfigMap{},
	).Named(
		"DXPMetadataConfigMapController",
	).WithEventFilter(
		predicate,
	).Complete(
		r,
	)
}

// func getExtensionNamespaceName(originNamespace string, virtualInstanceID string, applicationAlias string) (string, error) {
// 	// if len(applicationAlias) > 16 {
// 	// 	return "", fmt.Errorf("invalid applicationAlias: %s, length is greater than 16", applicationAlias)
// 	// }

// 	if !alphanumericRegex.MatchString(applicationAlias) {
// 		return "", fmt.Errorf("Invalid applicationAlias: %s, must only contain alphanumeric characters", applicationAlias)
// 	}

// 	virtualInstanceID = strings.ReplaceAll(virtualInstanceID, ".", "")

// 	// lengthOfApplicationAlias := len(applicationAlias)
// 	// originNamespaceHash := Xxhash3(originNamespace)
// 	// virtualInstanceIDHash := Xxhash3(virtualInstanceID)

// 	// if len(originNamespace) > (63 - 5 - lengthOfApplicationAlias) {
// 	// 	originNamespace = originNamespace[:20] + originNamespaceHash
// 	// }

// 	// if len(virtualInstanceID) > (63 - 5 - lengthOfApplicationAlias - len(originNamespace)) {
// 	// 	virtualInstanceID = virtualInstanceID[:(63-5-lengthOfApplicationAlias-len(originNamespace)-4)] + virtualInstanceIDHash
// 	// }

// 	return fmt.Sprintf("cx-%s-%s-%s", originNamespace, virtualInstanceID, applicationAlias), nil
// }

type DXPMetadataConfigMapController struct {
	client.Client
}

var alphanumericRegex = regexp.MustCompile("^[a-zA-Z0-9]+$")
