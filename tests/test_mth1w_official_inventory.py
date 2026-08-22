import copy

import pytest

from tools.mth1w_official_inventory import (
    DEFAULT_INVENTORY_PATH,
    EXPECTATION_PAGES,
    InventoryError,
    load_inventory,
    verify_inventory,
)


def current_inventory():
    return load_inventory(DEFAULT_INVENTORY_PATH)


def test_current_inventory_has_the_complete_official_hierarchy():
    payload = current_inventory()

    verify_inventory(payload)
    assert payload["counts"] == {
        "strands": 7,
        "overall_expectations": 14,
        "specific_expectations": 43,
        "expectations_total": 57,
    }
    assert [record["id"] for record in payload["records"]] == list(
        EXPECTATION_PAGES
    )
    assert payload["source"]["verbatim_expectation_text_included"] is False
    assert all("description" not in record for record in payload["records"])


@pytest.mark.parametrize(
    ("field", "value", "message"),
    [
        ("official_page", 1, "official page mismatch"),
        ("title", "Changed title", "title mismatch"),
        ("description_sha256", "0" * 64, "records digest mismatch"),
    ],
)
def test_inventory_record_mutations_are_rejected(field, value, message):
    payload = copy.deepcopy(current_inventory())
    payload["records"][0][field] = value

    with pytest.raises(InventoryError, match=message):
        verify_inventory(payload)


def test_verbatim_expectation_claim_is_rejected():
    payload = copy.deepcopy(current_inventory())
    payload["source"]["verbatim_expectation_text_included"] = True

    with pytest.raises(InventoryError, match="must not redistribute"):
        verify_inventory(payload)
