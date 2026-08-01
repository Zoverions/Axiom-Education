class WorkedExampleStep {
  const WorkedExampleStep({required this.label, required this.explanation});

  final String label;
  final String explanation;
}

class Mth1wFoundationLesson {
  const Mth1wFoundationLesson({
    required this.sequence,
    required this.expectationId,
    required this.title,
    required this.estimatedMinutes,
    required this.whyItMatters,
    required this.learningGoals,
    required this.prerequisites,
    required this.directInstruction,
    required this.workedExamplePrompt,
    required this.workedExampleSteps,
    required this.commonMisconception,
    required this.reflectionPrompt,
  });

  final int sequence;
  final String expectationId;
  final String title;
  final int estimatedMinutes;
  final String whyItMatters;
  final List<String> learningGoals;
  final List<String> prerequisites;
  final String directInstruction;
  final String workedExamplePrompt;
  final List<WorkedExampleStep> workedExampleSteps;
  final String commonMisconception;
  final String reflectionPrompt;
}

const List<Mth1wFoundationLesson> mth1wFoundationLessons = [
  Mth1wFoundationLesson(
    sequence: 1,
    expectationId: 'MTH1W-A1',
    title: 'Order of operations with rational numbers',
    estimatedMinutes: 20,
    whyItMatters:
        'A shared operation order makes calculations unambiguous and supports '
        'later work with formulas, algebra, and scientific notation.',
    learningGoals: [
      'Evaluate expressions containing integers and rational numbers.',
      'Explain why each operation is performed in its position.',
    ],
    prerequisites: [
      'Add, subtract, multiply, and divide signed numbers.',
      'Recognize grouping symbols and equivalent fractions.',
    ],
    directInstruction:
        'Work inside grouping symbols first. Then evaluate exponents. Perform '
        'multiplication and division from left to right, followed by addition '
        'and subtraction from left to right. Record each intermediate line so '
        'that signs and operation order remain visible.',
    workedExamplePrompt: 'Evaluate 18 − 3 × (4 − 6).',
    workedExampleSteps: [
      WorkedExampleStep(
        label: 'Resolve the grouping symbols',
        explanation: '4 − 6 = −2, so the expression becomes 18 − 3 × (−2).',
      ),
      WorkedExampleStep(
        label: 'Multiply before subtracting',
        explanation: '3 × (−2) = −6, so the expression becomes 18 − (−6).',
      ),
      WorkedExampleStep(
        label: 'Finish and check the signs',
        explanation: 'Subtracting a negative adds its opposite: 18 + 6 = 24.',
      ),
    ],
    commonMisconception:
        'Do not automatically work from left to right across every operation. '
        'Multiplication must be completed before the final subtraction.',
    reflectionPrompt:
        'Before calculating, identify the first operation and explain why it '
        'must come first.',
  ),
  Mth1wFoundationLesson(
    sequence: 2,
    expectationId: 'MTH1W-A2',
    title: 'Percentages and proportional reasoning',
    estimatedMinutes: 20,
    whyItMatters:
        'Percentages and proportions appear in discounts, taxes, interest, '
        'measurement, data, and comparisons across many high-school courses.',
    learningGoals: [
      'Move accurately among fraction, decimal, and percent forms.',
      'Use a proportional relationship to find an unknown amount.',
    ],
    prerequisites: [
      'Multiply and divide decimals.',
      'Interpret a fraction as division and simplify ratios.',
    ],
    directInstruction:
        'A percent is a rate per 100. Convert p% to p ÷ 100 before multiplying '
        'by the whole amount. For a missing value in a proportion, keep the '
        'units aligned and apply the same scale factor to both quantities.',
    workedExamplePrompt: 'Find 18% of 250.',
    workedExampleSteps: [
      WorkedExampleStep(
        label: 'Convert the percent',
        explanation: '18% = 18 ÷ 100 = 0.18.',
      ),
      WorkedExampleStep(
        label: 'Multiply by the whole',
        explanation: '0.18 × 250 = 45.',
      ),
      WorkedExampleStep(
        label: 'Check whether the result is reasonable',
        explanation:
            '20% of 250 is 50, so a value slightly below 50 is reasonable.',
      ),
    ],
    commonMisconception:
        '18% is 0.18, not 18. Dividing by 100 before multiplying prevents an '
        'answer that is one hundred times too large.',
    reflectionPrompt:
        'Estimate with a nearby friendly percent before calculating the exact '
        'answer.',
  ),
  Mth1wFoundationLesson(
    sequence: 3,
    expectationId: 'MTH1W-B2',
    title: 'Solving linear equations',
    estimatedMinutes: 25,
    whyItMatters:
        'Equations model unknown quantities in mathematics, science, business, '
        'and technology. Solving them depends on preserving equality.',
    learningGoals: [
      'Isolate an unknown by applying inverse operations.',
      'Verify a solution by substituting it into the original equation.',
    ],
    prerequisites: [
      'Evaluate expressions with signed numbers.',
      'Recognize inverse operations and combine like terms.',
    ],
    directInstruction:
        'Treat an equation like a balanced scale. Apply the same valid '
        'operation to both sides, undoing addition or subtraction before '
        'multiplication or division. Keep the original equation available for '
        'a final substitution check.',
    workedExamplePrompt: 'Solve 4x − 7 = 21.',
    workedExampleSteps: [
      WorkedExampleStep(
        label: 'Undo the subtraction',
        explanation: 'Add 7 to both sides: 4x − 7 + 7 = 21 + 7, so 4x = 28.',
      ),
      WorkedExampleStep(
        label: 'Isolate x',
        explanation: 'Divide both sides by 4: x = 7.',
      ),
      WorkedExampleStep(
        label: 'Verify the solution',
        explanation: 'Substitute x = 7: 4(7) − 7 = 28 − 7 = 21.',
      ),
    ],
    commonMisconception:
        'An operation performed on only one side changes the equality. Write '
        'the same operation on both sides before simplifying.',
    reflectionPrompt:
        'Name the operation attached to x that you will undo first, and state '
        'the inverse operation.',
  ),
  Mth1wFoundationLesson(
    sequence: 4,
    expectationId: 'MTH1W-B4',
    title: 'Equation of a line from two points',
    estimatedMinutes: 25,
    whyItMatters:
        'Linear equations describe constant rates of change and support models '
        'for distance, cost, growth, and experimental data.',
    learningGoals: [
      'Calculate slope from two points using a consistent subtraction order.',
      'Determine the y-intercept and write an equation in y = mx + b form.',
    ],
    prerequisites: [
      'Plot ordered pairs and work with signed fractions.',
      'Substitute values into an equation and solve for one unknown.',
    ],
    directInstruction:
        'For points (x₁, y₁) and (x₂, y₂), calculate slope with '
        'm = (y₂ − y₁) ÷ (x₂ − x₁). Keep the subtraction order consistent in '
        'the numerator and denominator. Substitute either point into '
        'y = mx + b to find b, then verify the other point.',
    workedExamplePrompt: 'Find the line through (1, 3) and (4, 9).',
    workedExampleSteps: [
      WorkedExampleStep(
        label: 'Calculate the slope',
        explanation: 'm = (9 − 3) ÷ (4 − 1) = 6 ÷ 3 = 2.',
      ),
      WorkedExampleStep(
        label: 'Find the intercept',
        explanation: 'Use (1, 3): 3 = 2(1) + b, so b = 1.',
      ),
      WorkedExampleStep(
        label: 'Write and verify the equation',
        explanation: 'The line is y = 2x + 1. At x = 4, y = 9 as required.',
      ),
    ],
    commonMisconception:
        'Reversing only one subtraction changes the sign of the slope. If the '
        'y-values use second minus first, the x-values must do the same.',
    reflectionPrompt:
        'Predict whether the slope is positive or negative from the two points '
        'before applying the formula.',
  ),
];
