/// Exact, host-supplied compatibility proof for the Axiom Education seam.
///
/// This object grants no authority. It only proves that a host was reviewed
/// against the same AXIOM-MESH contract surfaces as this application build.
class AxiomMeshCompatibilityProfile {
  static const currentProfileId =
      'axiom-education.mesh-0.12.0-dev.3-provider-v1';
  static const currentKernelVersion = '0.12.0-dev.3';
  static const currentBaselineHead = 'e816136db24196cd82f34ee1e0e8291af1ea155f';
  static const currentProviderHead = '2365bf5ed19e0da81288551b2bb4135a7094d02b';
  static const currentGatewayContractSourceHead =
      'e816136db24196cd82f34ee1e0e8291af1ea155f';
  static const currentGatewayContractCanonicalSha256 =
      '77d57f3f031ef0c8f777b0c77a4560fe3b9bacf8c14935ffc7a917b677544ddd';
  static const currentGatewayCompatibilityMode =
      'semantic-intents-submit-seam-with-additive-route-tolerance';
  static const currentGatewayIntentsSubmitSeamSha256 =
      'f595c1274eb98b7bcea33d72756120c491049e056cd0c9b3dd8dfd2d63d34f01';
  static const currentAuthorityPath = <String>[
    'Gateway',
    'Hypervisor',
    'Sandbox',
    'Grid',
  ];
  static const currentRequiredContractSha256 = <String, String>{
    'axiom.education.v1':
        'a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2',
    'axiom.education.learner-memory.v1':
        '3763a28919d36721467160ef772e30da1d5a536a8733fd88b65f2c60c9107d78',
  };

  final String profileId;
  final String kernelVersion;

  /// Observed Mesh main head for provenance. This is not a runtime authority
  /// pin because unrelated additive Mesh work must not invalidate Education.
  final String baselineHead;
  final String providerHead;

  /// Observed full Gateway contract provenance. Runtime compatibility is
  /// instead bound to [gatewayIntentsSubmitSeamSha256].
  final String gatewayContractSourceHead;
  final String gatewayContractCanonicalSha256;
  final String gatewayCompatibilityMode;
  final String gatewayIntentsSubmitSeamSha256;
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
    required this.gatewayIntentsSubmitSeamSha256,
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
      gatewayContractCanonicalSha256 = currentGatewayContractCanonicalSha256,
      gatewayCompatibilityMode = currentGatewayCompatibilityMode,
      gatewayIntentsSubmitSeamSha256 = currentGatewayIntentsSubmitSeamSha256,
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
        providerHead != currentProviderHead) {
      return 'Mesh profile, kernel, or provider source pin does not match this build.';
    }
    if (gatewayCompatibilityMode != currentGatewayCompatibilityMode ||
        gatewayIntentsSubmitSeamSha256 !=
            currentGatewayIntentsSubmitSeamSha256) {
      return 'Gateway intents.submit semantic seam does not match this build.';
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
