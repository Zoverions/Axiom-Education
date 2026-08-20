/// Exact, host-supplied compatibility proof for the Axiom Education seam.
///
/// This object grants no authority. It only proves that a host was reviewed
/// against the same AXIOM-MESH contract surfaces as this application build.
class AxiomMeshCompatibilityProfile {
  static const currentProfileId =
      'axiom-education.mesh-0.12.0-dev.3-provider-v1';
  static const currentKernelVersion = '0.12.0-dev.3';
  static const currentBaselineHead =
      'eb3614b3f8ccdd6c7f6367ceaaec5cc43c306534';
  static const currentProviderHead =
      '2365bf5ed19e0da81288551b2bb4135a7094d02b';
  static const currentGatewayContractSourceHead =
      'eb3614b3f8ccdd6c7f6367ceaaec5cc43c306534';
  static const currentGatewayContractCanonicalSha256 =
      '77d57f3f031ef0c8f777b0c77a4560fe3b9bacf8c14935ffc7a917b677544ddd';
  static const currentGatewayCompatibilityMode =
      'pinned-v1-intents-submit-seam-with-additive-read-route-tolerance';
  static const currentAuthorityPath = <String>[
    'Gateway',
    'Hypervisor',
    'Sandbox',
    'Grid',
  ];
  static const currentRequiredContractSha256 = <String, String>{
    'axiom.education.v1':
        'a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2',
    'axiom-gateway-client-contract.v1':
        '1d639b06adcf046ff19dab096a9b92134cbaaba8367c2331c10bc37a3c826949',
    'axiom-gateway-client-contract.schema.v1':
        'bae7fad4b6e6cc5e0181ebb799f13fac3b797dcfd6f9c00c4f3b23339a5413b2',
    'axiom.agent-runtime-adapter.v1':
        '4954c3d1a49ea57fb0bf5a7eea29140b852e8b5fa2bb11634665f004aca2c19c',
    'axiom.education.learner-memory.v1':
        '3763a28919d36721467160ef772e30da1d5a536a8733fd88b65f2c60c9107d78',
  };

  final String profileId;
  final String kernelVersion;
  final String baselineHead;
  final String providerHead;
  final String gatewayContractSourceHead;
  final String gatewayContractCanonicalSha256;
  final String gatewayCompatibilityMode;
  final List<String> authorityPath;
  final Map<String, String> requiredContractSha256;
  final bool nativeLearnerSelfWrite;
  final bool nativeLearnerSelfRead;
  final bool delegatedHumanAuthority;
  final bool axiomHostProfile;
  final bool assuranceGraph;
  final bool providerObservation;
  final bool checkoutFreshness;
  final bool localTrustActivation;
  final bool releasedArtifactPinsWithoutSubmodule;
  final bool gatewayIsOnlyNetworkAuthorityEntry;
  final bool directInternalServiceAccessAllowed;
  final bool contractPresenceGrantsAuthority;
  final bool installationGrantsLearnerDataAccess;
  final bool draftsMayPromoteThemselves;
  final bool applicationOwnsKernelAuthority;

  const AxiomMeshCompatibilityProfile({
    required this.profileId,
    required this.kernelVersion,
    required this.baselineHead,
    required this.providerHead,
    required this.gatewayContractSourceHead,
    required this.gatewayContractCanonicalSha256,
    required this.gatewayCompatibilityMode,
    required this.authorityPath,
    required this.requiredContractSha256,
    required this.nativeLearnerSelfWrite,
    required this.nativeLearnerSelfRead,
    required this.delegatedHumanAuthority,
    required this.axiomHostProfile,
    required this.assuranceGraph,
    required this.providerObservation,
    required this.checkoutFreshness,
    required this.localTrustActivation,
    required this.releasedArtifactPinsWithoutSubmodule,
    required this.gatewayIsOnlyNetworkAuthorityEntry,
    required this.directInternalServiceAccessAllowed,
    required this.contractPresenceGrantsAuthority,
    required this.installationGrantsLearnerDataAccess,
    required this.draftsMayPromoteThemselves,
    required this.applicationOwnsKernelAuthority,
  });

  const AxiomMeshCompatibilityProfile.current()
    : profileId = currentProfileId,
      kernelVersion = currentKernelVersion,
      baselineHead = currentBaselineHead,
      providerHead = currentProviderHead,
      gatewayContractSourceHead = currentGatewayContractSourceHead,
      gatewayContractCanonicalSha256 =
          currentGatewayContractCanonicalSha256,
      gatewayCompatibilityMode = currentGatewayCompatibilityMode,
      authorityPath = currentAuthorityPath,
      requiredContractSha256 = currentRequiredContractSha256,
      nativeLearnerSelfWrite = true,
      nativeLearnerSelfRead = true,
      delegatedHumanAuthority = false,
      axiomHostProfile = false,
      assuranceGraph = false,
      providerObservation = false,
      checkoutFreshness = false,
      localTrustActivation = false,
      releasedArtifactPinsWithoutSubmodule = true,
      gatewayIsOnlyNetworkAuthorityEntry = true,
      directInternalServiceAccessAllowed = false,
      contractPresenceGrantsAuthority = false,
      installationGrantsLearnerDataAccess = false,
      draftsMayPromoteThemselves = false,
      applicationOwnsKernelAuthority = false;

  /// Returns a reason when the host profile cannot bind, otherwise `null`.
  String? bindingRejectionReason() {
    if (profileId != currentProfileId ||
        kernelVersion != currentKernelVersion ||
        baselineHead != currentBaselineHead ||
        providerHead != currentProviderHead) {
      return 'Mesh baseline or provider source pin does not match this build.';
    }
    if (gatewayContractSourceHead != currentGatewayContractSourceHead ||
        gatewayContractCanonicalSha256 !=
            currentGatewayContractCanonicalSha256 ||
        gatewayCompatibilityMode != currentGatewayCompatibilityMode) {
      return 'Current Gateway compatibility observation does not match this build.';
    }
    if (!_sameList(authorityPath, currentAuthorityPath)) {
      return 'Mesh authority path must remain Gateway -> Hypervisor -> Sandbox -> Grid.';
    }
    if (!_sameMap(requiredContractSha256, currentRequiredContractSha256)) {
      return 'Required Mesh contract digests do not match this build.';
    }
    if (!nativeLearnerSelfWrite || !nativeLearnerSelfRead) {
      return 'Native learner self-write and self-read conformance is incomplete.';
    }
    if (delegatedHumanAuthority ||
        axiomHostProfile ||
        assuranceGraph ||
        providerObservation ||
        checkoutFreshness ||
        localTrustActivation) {
      return 'An observed draft or readiness-only Mesh feature was promoted without a new reviewed profile.';
    }
    if (!releasedArtifactPinsWithoutSubmodule) {
      return 'Mesh contracts must be consumed as pinned artifacts, not a repository submodule.';
    }
    if (!gatewayIsOnlyNetworkAuthorityEntry ||
        directInternalServiceAccessAllowed ||
        contractPresenceGrantsAuthority ||
        installationGrantsLearnerDataAccess ||
        draftsMayPromoteThemselves ||
        applicationOwnsKernelAuthority) {
      return 'Mesh authority invariants do not match the Axiom Education boundary.';
    }
    return null;
  }

  static bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool _sameMap(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) return false;
    for (final entry in right.entries) {
      if (left[entry.key] != entry.value) return false;
    }
    return true;
  }
}
